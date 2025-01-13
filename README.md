# Datarade Coding Challenge
The entire code is divided into 2 folders:
1. main-challenge
2. start-here

## main-challenge
This folder contains the code that is specific to the requirement. This has some prerequisites:
- You already have GitLab installed.
- A runner configured.
- You have AWS account. AWS CLI access is configured on GitLab runner.
- Terraform installed on the runner.

Once you place this code in the git repository in the 'main' branch the pipeline starts. The pipeline then creates:
- VPC and Subnets (2 public, 1 private and 2 db subnets for db subnet group)
- Postgres DB deployed under RDS into the db subnet group. The user and password are automatically created and stored in AWS secrets.
- An EC2 is created in the private subnet. Minikube is installed on the EC2. The same EC2 is configured as another runner for GitLab
- A bastion server is created in a public subnet which is used as a jump server to connect to the application server (the EC2 with Minikube installed.)
- Python is deployed on the Minikube cluster.

## start-here
This folder contains the terraform code to set-up the GitLab server itself. So, if you don't have GitLab already, you can run the terraform code in this folder and a GitLab server is set-up with predefined server. A runner is configured on the same server, terraform installed on the server too.

The installation of GitLab server takes some time after the server is up and running. Typically, it will take around 20 minutes. You can verify the log `/tmp/gitlab.log` on the server to check the progress of the GitLab installation.

Once you have the GitLab all set up, you can create a project and clone it to your local and then you put all this code into that repo and push it in the main branch. This will trigger the pipeline which triggers the steps in *main-challenge*.

## TODO
There are more things I am brining into the picture:
- Configure SSL and encryption throughout the CI/CD and application.
- Tightening the AWS permission policy.
- Creating ALB on top of application.
- Implimenting monitoring with Prometheus and Grafana. A different or the same ALB on top of monitoring tools.
- Reformat code. More detailed documentation with UML diagrams.

All this TODO should take not more than a week from now.