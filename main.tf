terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# --------------------------------------------------
# ENVIRONMENT CONFIGURATION
# --------------------------------------------------

locals {
  environment = terraform.workspace

  config = {
    dev = {
      vpc_cidr      = "10.10.0.0/16"
      subnet_cidr   = "10.10.1.0/24"
      instance_type = "t3.micro"
    }

    prod = {
      vpc_cidr      = "10.20.0.0/16"
      subnet_cidr   = "10.20.1.0/24"
      instance_type = "t3.medium"
    }
  }

  env = local.config[local.environment]
}

# --------------------------------------------------
# VPC
# --------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = local.env.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.environment}-vpc"
    Environment = local.environment
  }
}

# --------------------------------------------------
# SUBNET
# --------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.env.subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.environment}-public-subnet"
    Environment = local.environment
  }
}

# --------------------------------------------------
# INTERNET GATEWAY
# --------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.environment}-igw"
  }
}

# --------------------------------------------------
# ROUTE TABLE
# --------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --------------------------------------------------
# SECURITY GROUP
# --------------------------------------------------

resource "aws_security_group" "ec2" {
  name   = "${local.environment}-ec2-sg"
  vpc_id = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # Production-ல் உங்கள் IP மட்டும் கொடுப்பது நல்லது
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.environment}-ec2-sg"
    Environment = local.environment
  }
}

# --------------------------------------------------
# EC2
# --------------------------------------------------

resource "aws_instance" "server" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = local.env.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  associate_public_ip_address = true

  tags = {
    Name        = "${local.environment}-server"
    Environment = local.environment
  }
}

# --------------------------------------------------
# OUTPUTS
# --------------------------------------------------

output "environment" {
  value = local.environment
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "ec2_instance_id" {
  value = aws_instance.server.id
}

output "ec2_public_ip" {
  value = aws_instance.server.public_ip
}