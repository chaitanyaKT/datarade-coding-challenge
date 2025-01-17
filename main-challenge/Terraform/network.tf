data "aws_availability_zones" "test_web_app_azs" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dr-cc-app-vpc"
  cidr = var.net.cidr

  azs              = data.aws_availability_zones.test_web_app_azs.names
  public_subnets   = [cidrsubnet(var.net.cidr, 8, 1), cidrsubnet(var.net.cidr, 8, 2)]
  private_subnets  = [cidrsubnet(var.net.cidr, 8, 3)]
  database_subnets = [cidrsubnet(var.net.cidr, 8, 4), cidrsubnet(var.net.cidr, 8, 5)]

  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "dr-cc-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "dr-cc-app-instance"
      }
    }
  }

  target_groups = {
    dr-cc-app-instance  = {
      name_prefix      = "dr-app"
      protocol         = "HTTP"
      port             = 8001
      target_type      = "instance"
      target_id        = module.minikube-app-cluster.id
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }
}

resource "aws_db_subnet_group" "dr_cc_db_sn" {
  name       = "dr_cc_db_sn"
  subnet_ids = module.vpc.database_subnets

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }
}


module "public_sg" {
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

module "app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "dr-cc-app-sg"
  description = "Security group for application"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.public_sg.security_group_id
    },
    {
      from_port                = 8001
      to_port                  = 8001
      protocol                 = "tcp"
      source_security_group_id = module.public_sg.security_group_id
    },
    {
      from_port                = 8001
      to_port                  = 8001
      protocol                 = "tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "dr-cc-pg-db-sg"
  description = "Security group for PG DB from application"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 9876
      to_port                  = 9876
      protocol                 = "tcp"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}