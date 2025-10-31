provider "aws" {
  region = var.aws_region
}

# VARIABLES
variable "aws_region" {
  description = "AWS region to deploy resources in"
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  default     = "terraformgb-s3-bucket"
}

variable "environment" {
  description = "Environment tag for resources"
  default     = "Dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/24"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/28"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  default     = "ap-south-1b"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  default     = "ami-02d26659fd82cf299"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for EC2 SSH access"
  default     = "KeyTerra"
}

variable "instance_name" {
  description = "Name tag for EC2 instance"
  default     = "Terraform_ins"
}

# RANDOM ID FOR BUCKET
resource "random_id" "rand" {
  byte_length = 4
}

# S3 BUCKET
resource "aws_s3_bucket" "terraformgb_bucket" {
  bucket = "${var.bucket_prefix}-${random_id.rand.hex}"
  tags = {
    Name        = var.bucket_prefix
    Environment = var.environment
  }
}

# VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "TerraF_vpc"
  }
}

# SUBNET
resource "aws_subnet" "terra_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "Terra_subnet"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = "Terra_IGW"
  }
}

# ROUTE TABLE
resource "aws_route_table" "terra_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
  tags = {
    Name = "Terra_RouteTable"
  }
}

# ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "terra_rta" {
  subnet_id      = aws_subnet.terra_subnet.id
  route_table_id = aws_route_table.terra_rt.id
}

# SECURITY GROUP
resource "aws_security_group" "terra_sg" {
  name        = "terra-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "Terra_SecurityGroup"
  }
}

# EC2 INSTANCE
resource "aws_instance" "terraform_ins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.terra_subnet.id
  vpc_security_group_ids      = [aws_security_group.terra_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = var.instance_name
  }
}

# OUTPUTS
output "ec2_public_ip" {
  value = aws_instance.terraform_ins.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraformgb_bucket.bucket
}
