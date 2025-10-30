variable "name_prefix" { default = "bluegreen" }
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "target_group_arn" {}
variable "instance_profile" {}
variable "app_sg_id" {}
variable "key_name" {}
variable "user_data_file" {}
