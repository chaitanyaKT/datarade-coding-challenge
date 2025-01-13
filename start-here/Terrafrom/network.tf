data "aws_availability_zones" "test_web_app_azs" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dr-cc-cicd-vpc"
  cidr = var.net.cidr

  azs            = data.aws_availability_zones.test_web_app_azs.names
  public_subnets = [cidrsubnet(var.net.cidr, 8, 1)]

  create_igw = true

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }
}

module "ci_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "dc-cc-pg-ec2-sg"
  description = "Security group for bastion server"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "http-80-tcp"]

  # Outbound to private EC2s
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}