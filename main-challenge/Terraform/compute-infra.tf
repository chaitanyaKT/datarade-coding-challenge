# Bastion server for testing
module "dr_cc_bastion_ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "dr-cc-bastion-ec2"

  instance_type               = "t2.micro"
  key_name                    = "my_practice"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.public_sg.security_group_id]
  associate_public_ip_address = true
  depends_on                  = [module.vpc]
}

module "minikube-app-cluster" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "dr-cc-minikube-app-cluster"

  instance_type          = "t3a.xlarge"
  key_name               = "my_practice"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.app_sg.security_group_id]

  user_data = base64encode(templatefile("${path.module}/files/app_userdata.sh", {
    GITLAB_URL         = var.GITLAB_URL
    REGISTRATION_TOKEN = var.REGISTRATION_TOKEN
  }))
  depends_on = [module.vpc, module.vpc.aws_nat_gateway]

  create_iam_instance_profile = true
  iam_role_name               = "dr-cc-app-ec2-profile-role"
  iam_role_policies = {
    "dr-cc-app-ec2-iam-role-policy" = aws_iam_policy.dr_cc_app_ec2_iam_policy.arn
  }
}

resource "aws_iam_policy" "dr_cc_app_ec2_iam_policy" {
  name        = "dr_cc_app_ec2_iam_policy"
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
}