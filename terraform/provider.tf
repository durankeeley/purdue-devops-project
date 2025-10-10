terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
