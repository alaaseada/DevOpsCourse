terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.8.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform_Demo"
  }
}
