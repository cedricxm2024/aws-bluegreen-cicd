#!/usr/bin/env python3
import os
import subprocess

def run(cmd):
    subprocess.run(cmd, shell=True, check=True)

def main():
    # Update system
    run("sudo apt update -y")

    # Install Apache
    run("sudo apt install -y apache2")

    # Start Apache service
    run("sudo systemctl enable apache2")
    run("sudo systemctl start apache2")

    # Write sample web page
    run("echo '<h1>Blue/Green Deployment Successful 🚀</h1>' | sudo tee /var/www/html/index.html")

if __name__ == "__main__":
    main()
