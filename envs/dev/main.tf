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
