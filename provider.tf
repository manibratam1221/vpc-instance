terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-bucket-westus"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}