terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-cedric-060e5289" # update to real bootstrap output
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-dev-cedric-060e5289"  # update to real value
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
module "vpc" {
  source             = "../../modules/vpc"
  region             = "us-east-1"
  name_prefix        = "bluegreen"
  public_subnet_cidrs  = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24","10.0.4.0/24"]
}

# Security groups
module "security" {
  source = "../../modules/security"
  vpc_id = module.vpc.vpc_id
  allow_ssh_cidr = "203.0.113.4/32"   # <<--- replace with your IP (NOT 0.0.0.0/0)
  name_prefix = "bluegreen"
}

# ALB
module "alb" {
  source = "../../modules/alb"
  subnet_ids = module.vpc.public_subnet_ids
  vpc_id     = module.vpc.vpc_id
  sg_id      = module.security.alb_sg_id
  name_prefix = "bluegreen"
}

output "alb_dns" {
  value = module.alb.alb_dns_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
# IAM Role for EC2
module "iam" {
  source      = "../../modules/iam"
  name_prefix = "bluegreen"
}

# Auto Scaling Group (with Apache setup)
module "asg" {
  source          = "../../modules/asg"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  target_group_arn = module.alb.target_group_arn
  instance_profile = module.iam.instance_profile_name
  app_sg_id       = module.security.app_sg_id
  key_name        = "key-060e52895183db7f9"  # your provided key pair
  user_data_file  = "../../scripts/user_data.py"
}
module "compute" {
  source             = "../../modules/compute"
  project_name       = var.project_name
  ami_id             = "ami-0c02fb55956c7d316" # Ubuntu Free Tier
  instance_type      = "t2.micro"
  key_name           = "key-060e52895183db7f9"
  ec2_sg_id          = module.vpc.ec2_sg_id
  public_subnet_ids  = module.vpc.public_subnets
  target_group_arn   = module.alb.alb_target_group_arn
}
module "cicd" {
  source = "../../modules/cicd"

  project_name          = "bluegreen"
  codebuild_role_arn    = module.iam.codebuild_role_arn
  codedeploy_role_arn   = module.iam.codedeploy_role_arn
  codepipeline_role_arn = module.iam.codepipeline_role_arn

  artifact_bucket  = "bluegreen-artifacts-cedric-060e5289"
  repo_owner       = "my-github-org"
  repo_name        = "my-app-repo"
  branch           = "main"
  connection_arn   = "arn:aws:codestar-connections:us-east-1:abcdefg"
  asg_name         = module.compute.asg_name
  target_group_name = module.alb.alb_target_group_name
}
