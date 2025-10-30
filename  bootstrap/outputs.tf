output "s3_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state."
  value       = aws_s3_bucket.tf_state.bucket
}

# DynamoDB table used for state locking
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.tf_lock.name
}

# KMS Key ARN 
output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Terraform state (if created)."
  value       = var.create_kms ? aws_kms_key.tf_state_key[0].arn : null
  sensitive   = false
}

# Terraform admin IAM role ARN 
output "terraform_admin_role_arn" {
  description = "ARN of the IAM role for Terraform administration (if created)."
  value       = aws_iam_role.terraform_admin_role.arn
  condition   = length(var.terraform_admin_principal_arns) > 0
}