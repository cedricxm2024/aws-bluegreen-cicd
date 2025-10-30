variable "project_name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string default = "t2.micro" }
variable "key_name" { type = string }
variable "ec2_sg_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "target_group_arn" { type = string }
