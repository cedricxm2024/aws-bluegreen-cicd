#!/usr/bin/env bash

set -e

# Check if Terraform is already installed
if command -v terraform &> /dev/null; then
  echo "Terraform is already installed: $(terraform version | head -n1)"
  exit 0
fi

echo "Installing Terraform..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# Get Ubuntu codename more reliably
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release 2>/dev/null || echo "jammy")

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt-get install terraform -y

echo "Terraform installed successfully: $(terraform version | head -n1)"