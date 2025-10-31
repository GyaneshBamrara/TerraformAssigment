provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "TerraF_vpc" {
  id = "vpc-07557001c6a5eb1b9"
}

data "aws_subnet" "Terra_subnet" {
  id = "subnet-03d4037033d0eb90f"
}

data "aws_instance" "Terraform_ins" {
  instance_id = "i-09e0d352f1e8d4da1"
}

data "aws_s3_bucket" "terraformgb_s3_bucket" {
  bucket = "terraformgb-s3-bucket"
}

data "aws_key_pair" "k3" {
  key_name = "k3"
}
