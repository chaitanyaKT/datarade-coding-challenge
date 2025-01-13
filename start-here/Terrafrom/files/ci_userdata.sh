#!/bin/bash
set -x

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Adding gitlab-runner user to sodoers
sudo echo "gitlab-runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gitlab-sudo

# Install GitLab
sudo dnf install -y policycoreutils-python-utils openssh-server openssh-clients perl

sudo systemctl enable sshd
sudo systemctl start sshd

# TODO to stop if firewalld is running
# TODO Postfix or another SMTP config

(
    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    sudo GITLAB_ROOT_EMAIL="root@gitlab.com" GITLAB_ROOT_PASSWORD="He!!o@123" EXTERNAL_URL="http://${PUBLIC_IP}" yum -y install gitlab-ee > /tmp/gitlab.log

    echo "Sleeping 3 minutes..." >> /tmp/gitlab.log
    sleep 180
    echo "Awake! Continuing with gitlab-runner" >> /tmp/gitlab.log

    # Installing GitLab Runner
    echo "Installing gitlab-runner" >> /tmp/gitlab.log
    REGISTRATION_TOKEN=$(sudo gitlab-rails runner "puts Gitlab::CurrentSettings.runners_registration_token")
    echo $REGISTRATION_TOKEN >> /tmp/gitlab.log
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash >> /tmp/gitlab.log
    sudo yum install -y gitlab-runner >> /tmp/gitlab.log
    sudo gitlab-runner register --non-interactive \
        --url "http://${PUBLIC_IP}/" \
        --registration-token "$REGISTRATION_TOKEN" \
        --executor "shell" \
        --description "ci-master" \
        --tag-list "master-runner,linux,shell" \
        --run-untagged="true" \
        --locked="false" >> /tmp/gitlab.log
) &