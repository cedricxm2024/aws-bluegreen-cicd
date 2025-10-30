#!/usr/bin/env bash

set -e

# Check if AWS CLI is already installed
if command -v aws &> /dev/null; then
  echo "AWS CLI is already installed: $(aws --version)"
  exit 0
fi

echo "Installing AWS CLI..."

# Check if unzip is installed
if ! command -v unzip &> /dev/null; then
  echo "unzip is not installed. Installing..."
  sudo apt-get update && sudo apt-get install -y unzip
fi

# Download AWS CLI
if ! curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; then
  echo "Error: Failed to download AWS CLI"
  exit 1
fi

# Extract the archive
if ! unzip -q awscliv2.zip; then
  echo "Error: Failed to extract AWS CLI archive"
  rm -f awscliv2.zip
  exit 1
fi

# Install AWS CLI
if ! sudo ./aws/install; then
  echo "Error: Failed to install AWS CLI"
  rm -rf awscliv2.zip aws/
  exit 1
fi

# Cleanup
rm -rf awscliv2.zip aws/

echo "AWS CLI installed successfully: $(aws --version)"