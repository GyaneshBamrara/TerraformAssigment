provider "aws" {
  region = "ap-south-1"
}

# Generate a random suffix for unique bucket name
resource "random_id" "rand" {
  byte_length = 4
}

# Create an S3 Bucket with a unique name
resource "aws_s3_bucket" "terraformgb_bucket" {
  bucket = "terraformgb-s3-bucket-${random_id.rand.hex}"
  tags = {
    Name        = "terraformgb-s3-bucket"
    Environment = "Dev"
  }
}

# Create a VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "TerraF_vpc"
  }
}

# Create a public subnet inside that VPC
resource "aws_subnet" "terra_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Terra_subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = "Terra_IGW"
  }
}

# Create a route table and attach to subnet
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

resource "aws_route_table_association" "terra_rta" {
  subnet_id      = aws_subnet.terra_subnet.id
  route_table_id = aws_route_table.terra_rt.id
}

# Create a security group
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

# Create EC2 Instance
resource "aws_instance" "terraform_ins" {
  ami                         = "ami-02d26659fd82cf299" # Ubuntu 24.04 LTS
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.terra_subnet.id
  vpc_security_group_ids      = [aws_security_group.terra_sg.id]
  associate_public_ip_address = true
  key_name = "KeyTerra"

  tags = {
    Name = "Terraform_ins"
  }
}
