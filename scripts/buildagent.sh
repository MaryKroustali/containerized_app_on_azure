#!/bin/bash
# Edit below commands based on guidelines in
# Github Repository Settings > Actions > Runners > New self-hosted runner (Linux)
# Additionally to run as a service follow instructions on
# https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service

# Define your variables
token="$1"
org="MaryKroustali"  # Replace with your GitHub organization name
repo="containerized_app_on_azure"  # Replace with your GitHub repository name

# Install helping tools
sudo apt-get update -y
sudo apt-get install jq -y

# Set Github Runner
cd /home/vmadmin/ # Create a folder under admin directory
mkdir actions-runner; cd actions-runner
curl -o actions-runner-linux-x64-2.323.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-x64-2.323.0.tar.gz # Download the latest runner package
tar xzf ./actions-runner-linux-x64-2.323.0.tar.gz # Extract the installer
response=$(curl -s -L \
  -X POST "https://api.github.com/repos/$org/$repo/actions/runners/registration-token" \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $token" \
  -H "X-GitHub-Api-Version: 2022-11-28")
registrationToken=$(echo "$response" | jq -r .token)
sudo chown -R vmadmin:vmadmin /home/vmadmin/actions-runner
sudo -u vmadmin ./config.sh --unattended --url https://github.com/$org/$repo/ --token $registrationToken --replace # Create the runner
sudo ./svc.sh install
sudo ./svc.sh start # Start running as a service

# Install az cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version

# Install Docker
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker --version