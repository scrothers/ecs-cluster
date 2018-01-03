# Configure AWS provider for access.
provider "aws" {
  region  = "us-east-1"
  profile = "sandbox"
}

data "aws_region" "current" {
  current = true
}

data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}
data "aws_availability_zones" "available" {}
