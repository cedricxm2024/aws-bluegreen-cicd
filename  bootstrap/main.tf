terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region = var.region
}

# ---------------------------
# Optional: KMS Key (CMK)
# ---------------------------
resource "aws_kms_key" "tf_state_key" {
  count       = var.create_kms ? 1 : 0
  description = "KMS CMK for encrypting Terraform state S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "Allow administration of the key"
        Effect = "Allow"
        Principal = { AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"] }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
  deletion_window_in_days = 7
  tags = {
    Name = "tf-state-key-${var.unique_suffix}"
    Env  = var.env
  }
}

resource "aws_kms_alias" "tf_state_key_alias" {
  count      = var.create_kms ? 1 : 0
  name       = "alias/tf-state-key-${var.unique_suffix}"
  target_key_id = aws_kms_key.tf_state_key[0].id
}

# ---------------------------
# S3 bucket for terraform state
# ---------------------------
locals {
  bucket_name = "terraform-state-${var.env}-${var.unique_suffix}"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.create_kms ? "aws:kms" : "AES256"
        kms_master_key_id = var.create_kms ? aws_kms_key.tf_state_key[0].arn : null
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "state-versions-retention"
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }

  tags = {
    Name = "terraform-state-${var.unique_suffix}"
    Env  = var.env
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------
# DynamoDB table for locking
# ---------------------------
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-${var.env}-${var.unique_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock-${var.unique_suffix}"
    Env  = var.env
  }
}

# ---------------------------
# S3 bucket policy limiting access to listed principals
# ---------------------------
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"
    principals { type = "AWS"; identifiers = ["*"] }
    actions   = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = var.create_kms ? ["aws:kms"] : ["AES256"]
    }
  }

  dynamic "statement" {
    for_each = length(var.terraform_admin_principal_arns) > 0 ? [1] : []
    content {
      sid    = "AllowTerraformAdmins"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.terraform_admin_principal_arns
      }
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.tf_state.arn,
        "${aws_s3_bucket.tf_state.arn}/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "tf_state_policy" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# ---------------------------
# IAM role for terraform admin
# ---------------------------
resource "aws_iam_role" "terraform_admin_role" {
  name = "terraform-admin-role-${var.unique_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = var.terraform_admin_principal_arns
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = { Name = "terraform-admin-role-${var.unique_suffix}" }
}

resource "aws_iam_policy" "terraform_admin_policy" {
  name = "terraform-admin-policy-${var.unique_suffix}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.tf_lock.arn
      },
      {
        Effect = var.create_kms ? "Allow" : "Deny",
        Action = var.create_kms ? [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ] : [],
        Resource = var.create_kms ? aws_kms_key.tf_state_key[0].arn : ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_tf_admin_policy" {
  count      = length(var.terraform_admin_principal_arns) > 0 ? 1 : 0
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = aws_iam_policy.terraform_admin_policy.arn
}

# ---------------------------
# Outputs
# ---------------------------
output "s3_bucket_name" {
  description = "S3 bucket storing Terraform state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tf_lock.name
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = var.create_kms ? aws_kms_key.tf_state_key[0].arn : ""
  sensitive   = false
}

output "terraform_admin_role_arn" {
  value = aws_iam_role.terraform_admin_role.arn
  description = "Terraform admin role ARN"
  depends_on  = [aws_iam_role.terraform_admin_role]
}
