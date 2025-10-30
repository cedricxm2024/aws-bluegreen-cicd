#!/usr/bin/env python3
import subprocess

def run_command(command):
    subprocess.run(command, shell=True, check=True)

# Update packages and install Apache
run_command("sudo apt-get update -y")
run_command("sudo apt-get install -y apache2")

# Enable and start Apache
run_command("sudo systemctl enable apache2")
run_command("sudo systemctl start apache2")

# Create a simple web page
html_content = """<html>
<head><title>Welcome to Blue/Green Deployment!</title></head>
<body>
<h1 style="color:blue;text-align:center;">Deployed via Terraform + AWS CodePipeline</h1>
<p style="text-align:center;">Served by $(hostname)</p>
</body>
</html>"""

with open("/var/www/html/index.html", "w") as f:
    f.write(html_content)
#!/usr/bin/env python3
import os
os.system("yum install -y awslogs")
os.system("systemctl enable awslogsd")
os.system("systemctl start awslogsd")
os.system("yum install -y amazon-xray-daemon")
os.system("systemctl enable xray")
os.system("systemctl start xray")
{
  "Effect": "Allow",
  "Action": [
    "xray:PutTraceSegments",
    "xray:PutTelemetryRecords"
  ],
  "Resource": "*"
}
