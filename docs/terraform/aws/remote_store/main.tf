terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    encrypt = true    
    #bucket = "${local.account_id}-terraform-state"
    dynamodb_table = "terraform-lock"
    key    = "terraform.tfstate"
    #region = var.aws_region
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Get and set alocal variable for account ID that authorized Terraform
#data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}


# Create an S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.account_id}-terraform-state"

  tags = {
    Name        = "Terraform bucket"
    Environment = "Dev"
  }
}

# Create an S3 bucket versioning
resource "aws_s3_bucket_versioning" "s3_terraform_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


# S3 bucket serverside Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_terraform_sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
  }
}
}

# Create the Dynamo db table
resource "aws_dynamodb_table" "terraform_state_lock_table" {
  name             = "terraform-lock"
  hash_key         = "LockID"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
