terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-cedric-060e5289"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-dev-cedric-060e5289"
    encrypt        = true
  }
}
