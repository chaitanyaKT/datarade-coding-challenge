#!/bin/bash
set -x

# Updating packages
sudo yum update -y
sudo yum install -y docker

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Starting up services
sudo systemctl daemon-reload

# Start docker
sudo systemctl start docker
sudo systemctl enable docker

# Install GitLab runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
sudo yum install -y gitlab-runner

# Install Minikube
sudo curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install and configure gitlab runner
sudo echo "gitlab-runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gitlab-sudo

sudo gitlab-runner register --non-interactive \
  --url "${GITLAB_URL}" \
  --registration-token "${REGISTRATION_TOKEN}" \
  --executor "shell" \
  --description "app-cluster" \
  --tag-list "linux,shell,app-runner" \
  --run-untagged="true" \
  --locked="false"

sudo usermod -aG docker gitlab-runner
sudo su - gitlab-runner -c "minikube start --driver=docker"
sudo su - gitlab-runner -c "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3; chmod 700 get_helm.sh; ./get_helm.sh"