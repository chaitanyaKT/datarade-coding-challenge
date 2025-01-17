# Datarade Coding Challenge
The entire code is divided into 2 folders:
1. main-challenge
2. start-here

## 1. main-challenge
This folder contains the code that is specific to the requirement. This has some prerequisites:
- You already have GitLab installed.
- A gitlab runner configured (with tag `master-runner`).
- You have AWS account. AWS CLI access is configured on GitLab runner.
- Terraform installed on the gitlab runner.

Once you place this code in the git repository in the 'main' branch the pipeline starts. The pipeline then creates:
- VPC and Subnets (2 public, 1 private and 2 db subnets for db subnet group)
- Postgres DB deployed under RDS into the db subnet group. The user and password are automatically created and stored in AWS secrets.
- An EC2 is created in the private subnet. Minikube and Helm is installed on the EC2. The same EC2 is configured as another runner for GitLab (with tag `app-runner`)
- An ALB in the public subnet that is exposed to internet. ALB is connected to the app in the minikube cluster.
- A bastion server is created in a public subnet which is used as a jump server to connect to the application server (the EC2 with Minikube installed.)
- Python app is deployed on the Minikube cluster.
- Prometheus-Grafana stack is installed in the same minikube cluster under the namespace `monitoring`

>CAUTION !<br>
> To destroy the resources easily:<br>
>You need to get hold of the console access from where the above terraform code is run, to destroy the resources easily with `terraform destroy`. If not, you will have to manually delete all the resources from AWS console.


After the completion of the CI pipeline, the full setup is completely deployed. You should be able to access:
- The application with the url:
    - `http://<ALB-public-endpoint>/api/v1/namespaces/default/services/my-app-service:8080/proxy/api/health`
    - `http://<ALB-public-endpoint>/api/v1/namespaces/default/services/my-app-service:8080/proxy/api/data?id=5`
    - `ALB-public-endpoint` is available in AWS console.
- Grafana is accessible at the url:
    - `http://<ALB-public-endpoint>/api/v1/namespaces/monitoring/services/prometheus-grafana:80/proxy/`

## 2. start-here
This folder contains the terraform code to set-up the GitLab server itself. So, if you don't have GitLab already, you can run the terraform code in this folder and a GitLab server is set-up.

This has the following prerequisites:
- AWS account will admin access.
- Configure AWS CLI access from where you run this terraform code (Local laptop).

Execution commands:
```
cd start-here/Terraform
terraform init
terraform plan -out tfplan
terraform apply --auto-approve tfplan
```

The installation of GitLab server takes several minutes after the server is up and running. Typically, it will take around 20-30 minutes. You can verify the log `/tmp/gitlab.log` on the server to check the progress of the GitLab installation.

After successfully running the terraform code in here:
- GitLab is installed on an EC2 server in AWS in the public subnet.
- Public IP is allocated to the EC2 instance.
- A runner is configured on the same server and terraform installed on the server too.

You can access GitLab at: `http://<Public-IP of the EC2>/`. You can see the root logins for GitLab in the file `start-here/Terraform/files/ci_userdata.sh` in the gitlab installation command (line 29)

Once you have the GitLab all set up, you can create a project and clone it to your local and then you put all this code into that repo and push it in the main branch. This will trigger the pipeline which triggers the steps in *main-challenge*.

## TODO
There are few more things I would brining into the picture:
- Configure SSL and encryption throughout the CI/CD and application.
    - Currently not implemented. It would be easier to implement SSL when we have fixed domain and IP.
- Tightening the AWS permission policy.
- Monitoring and alerting solution is currently only installed as a part of POC. It is not configured as we need running SMTP and few more things to fully configure it.

I do have experience in implementing all of the above TODO point once I could setup all the prerequisites. I only skipped them considering this a simple POC and focusing on the main taks (Creating DB and securly passing the DB credentials)