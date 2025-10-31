provider "aws" {
  region = "ap-south-1"
}

data "aws_subnet" "Terra_subnet" {
  id = "subnet-05f3e4ebf28c3f1de"
}

data "aws_vpc" "TerraF_vpc" {
  id = "vpc-07557001c6a5eb1b9"
}

data "aws_route_table" "public_rt" {
  id = "rtb-084bc8bdcac97607f"
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.TerraF_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "Terraform_ins" {
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 AMI for ap-south-1
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.Terra_subnet.id
  security_groups = [aws_security_group.web_sg.name]
  tags = {
    Name = "Terraform_ins"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "terraformgb-s3-bucket"
  tags = {
    Name = "terraformgb-s3-bucket"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
