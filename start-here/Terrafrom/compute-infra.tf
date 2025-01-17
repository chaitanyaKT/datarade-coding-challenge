module "cicd-ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "dr-cc-cicd-ec2"

  instance_type               = "c5.2xlarge"
  ami                         = "ami-05576a079321f21f8"
  key_name                    = "my_practice"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.ci_sg.security_group_id]
  associate_public_ip_address = true
  user_data                   = filebase64("${path.module}/files/ci_userdata.sh")
  depends_on                  = [module.vpc]

  enable_volume_tags = false
  root_block_device = [{
    delete_on_termination = true
    volume_size           = 15
    volume_type           = "gp2"

    tags = {
      Terraform   = "true"
      Environment = "dr-cc-dev"
    }
  }]

  create_iam_instance_profile = true
  iam_role_name               = "dr-cc-cicd-ec2-profile-role"
  iam_role_policies = {
    "dr-cc-cicd-ec2-iam-role-policy" = aws_iam_policy.dr_cc_cicd_ec2_iam_policy.arn
  }

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }

}

resource "aws_iam_policy" "dr_cc_cicd_ec2_iam_policy" {
  name        = "dr_cc_cicd_ec2_iam_policy"
  path        = "/"
  description = "IAM profile policy for CICD EC2 cluster"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "*",
          "Resource" : "*"
        }
      ]
    }
  )

  tags = {
    Terraform   = "true"
    Environment = "dr-cc-dev"
  }
}

output "ci_server_pub_id" {
  description = "The public IP of the CI server."
  value       = module.cicd-ec2.public_ip
}