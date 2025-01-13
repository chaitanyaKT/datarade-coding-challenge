from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text

import os
import logging
import json
import boto3

# Set up logging to output to the console
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration for the PostgreSQL database
# The database credentials are fetched from Kubernetes secrets through environment variables
# The actual username and password are fetched from AWS secrets
DB_CREDS = json.loads(os.getenv("DB_CREDS"))

secret_name = DB_CREDS.get("pg_db_secret").get("value")[0].get("secret_arn")
try:
    client = boto3.client("secretsmanager", region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)

    if "SecretString" in response:
        db_logins=json.loads(response["SecretString"])
    else:
        db_logins=json.loads(response["SecretBinary"].decode("utf-8"))
except Exception as e:
    logger.error(f"An error occurred: {e}")

DATABASE_USER = db_logins.get("username", "postgres")
DATABASE_PASSWORD = db_logins.get("password", "postgres")
DATABASE_HOST = DB_CREDS.get("DB_HOST").get("value")
DATABASE_PORT = DB_CREDS.get("DB_PORT").get("value")
DATABASE_NAME = DB_CREDS.get("DB_NAME").get("value")

logger.info("DB Url:")
logger.info(f"postgresql+psycopg2://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}")

# Construct the database URI
app.config['SQLALCHEMY_DATABASE_URI'] = (
    f"postgresql+psycopg2://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize the SQLAlchemy database instance
db = SQLAlchemy(app)

# Define the model for the table
# This represents the schema of the 'my_table' table in the database
class MyTable(db.Model):
    __tablename__ = 'my_table'  # Explicitly define the table name
    id = db.Column(db.Integer, primary_key=True)  # Primary key column
    name = db.Column(db.String(50), nullable=False)  # Name column, cannot be null

def initialize_database():
    logger.debug("Initializing database...")
    # Use the SQLAlchemy inspect API to check if the 'my_table' exists
    inspector = inspect(db.engine)
    if not inspector.has_table('my_table'):
        logger.info("Table 'my_table' does not exist. Creating and populating...")
        db.create_all()  # Create all tables defined in the models
        for i in range(1, 11):  # Populate the table with 10 rows
            row = MyTable(id=i, name=f"Row {i}")  # Create a new row
            db.session.add(row)  # Add the row to the session
            logger.debug(f"Added row: {row}")  # Debug log
        db.session.commit()  # Commit all changes to the database
        logger.info("Database initialization complete.")
    else:
        logger.info("Table 'my_table' already exists. Skipping initialization.")

@app.route('/api/data', methods=['GET'])
def get_data():
    logger.debug("Processing /api/data request...")
    # Retrieve the 'id' parameter from the request query string
    row_id = request.args.get('id', type=int)
    if not row_id:  # If 'id' is missing or invalid
        logger.error("Missing 'id' parameter")
        return jsonify({"error": "Missing 'id' parameter"}), 400

    logger.debug(f"Fetching row with id: {row_id}")
    row = MyTable.query.get(row_id)  # Fetch the row with the specified ID
    if not row:  # If no row is found
        logger.error("Row not found")
        return jsonify({"error": "Row not found"}), 404

    logger.debug(f"Row found: {row}")  # Debug log
    return jsonify({"id": row.id, "name": row.name})  # Return the row data as JSON

@app.route('/api/health', methods=['GET'])
def health_check():
    logger.debug("Processing /api/health request...")
    try:
        db.session.execute(text('SELECT 1'))  # Test the database connection using text()
        logger.info("Database connection is healthy.")  # Debug log
        return jsonify({"status": "healthy"}), 200
    except Exception as e:  # Handle any errors
        logger.error(f"Database connection error: {e}")  # Debug log
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting application...")
    with app.app_context():  # Ensure the application context is available
        initialize_database()  # Initialize the database on startup
    logger.info("Application is running on http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000)  # Start the Flask application
