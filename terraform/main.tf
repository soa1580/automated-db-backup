terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "Automated Database Backups"
    Environment = "Production"
    Project     = "automated-db-backup"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "backup_bucket" {
  bucket = aws_s3_bucket.backup_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup_bucket" {
  bucket = aws_s3_bucket.backup_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup_bucket" {
  bucket = aws_s3_bucket.backup_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
