provider "aws" {
  region = var.aws_region
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_s3_bucket" "terraformgb_bucket" {
  bucket = "${var.bucket_prefix}-${random_id.rand.hex}"
  tags = {
    Name        = var.bucket_prefix
    Environment = var.environment
  }
}

resource "aws_vpc" "terra_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "terra_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = var.subnet_name
  }
}

resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "terra_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "terra_rta" {
  subnet_id      = aws_subnet.terra_subnet.id
  route_table_id = aws_route_table.terra_rt.id
}

resource "aws_security_group" "terra_sg" {
  name        = var.sg_name
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
    Name = var.sg_name
  }
}

resource "aws_instance" "terraform_ins" {
  ami                         = var.ami_id
_group.terra_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
   TerraF_vpc"
}

variable "subnet_cidr" {
  default = "10.0.0.0/28"
}

variable "availability_zone" {
  default = "ap-south-1b"
}

variable "subnet_name" {
  default = "Terra_subnet"
}

variable "igw_name" {
  default = "Terra_IGW"
}

variable "route_table_name" {
  default = "Terra_RouteTable"
}

variable "sg_name" {
  default = "Terra_SecurityGroup"
}

variable "ami_id" {
  default = "ami-02d26659fd82cf299"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "KeyTerra"
}

variable "instance_name" {
  default = "Terraform_ins"
}
