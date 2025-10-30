variable "region" {
  description = "AWS region for backend"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment suffix (dev, prod)"
  type        = string
  default     = "bootstrap"
}

variable "unique_suffix" {
  description = "Unique suffix to avoid global name collisions"
  type        = string
  default     = "cedric-060e5289"
}

variable "create_kms" {
  description = "Set true to create a CMK and use SSE-KMS for the bucket"
  type        = bool
  default     = false
}

variable "terraform_admin_principal_arns" {
  description = "List of IAM principals (role/user ARNs) that should be allowed to read/write state"
  type        = list(string)
  default     = []
}
