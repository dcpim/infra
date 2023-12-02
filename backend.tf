terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "latest"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "${var.region}"
}
