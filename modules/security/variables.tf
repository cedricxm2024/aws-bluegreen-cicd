variable "vpc_id" {}
variable "allow_ssh_cidr" {
  description = "CIDR allowed to SSH into instances during dev. Do not use 0.0.0.0/0 in production."
  type        = string
  default     = "0.0.0.0/0" # change this to your public IP e.g., "203.0.113.4/32"
}
variable "name_prefix" { default = "bluegreen" }
