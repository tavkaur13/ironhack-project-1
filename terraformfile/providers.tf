terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
 }
  backend "s3" {
    bucket         = "tavleen-terraform-state-bucket"  # Replace with your actual S3 bucket name
    key            = "terraform.tfstate"          # The file path to store the state
    region         = "us-east-1"                  # Your AWS region
    encrypt        = true                         # Encrypt state file at rest
    dynamodb_table = "tavleen-terraform-state-lock"       # DynamoDB table for state locking
  }
}

provider "aws" {
  region = var.aws_region
}
