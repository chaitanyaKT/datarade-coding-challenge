terraform {
  required_version = ">=1.9.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
  }

  # Use s3 backend
  # backend "s3" {
  #   bucket = "<s3-bucket>"
  #   key    = "terraform/state/dr-cc-start-state/terraform.tfstate"
  #   region = "us-east-1"
  # }
}