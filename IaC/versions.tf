terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.82.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}
