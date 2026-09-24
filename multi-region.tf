terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# =========================================================
# PROVIDER - MUMBAI
# =========================================================

provider "aws" {
  region = "ap-south-1"
}

# =========================================================
# PROVIDER - SINGAPORE
# =========================================================

provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

# =========================================================
# MUMBAI VPC
# =========================================================

resource "aws_vpc" "mumbai" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "mumbai-dr-vpc"
    Region      = "Mumbai"
    Environment = "DR"
  }
}

# =========================================================
# MUMBAI SUBNET
# =========================================================

resource "aws_subnet" "mumbai" {
  vpc_id                  = aws_vpc.mumbai.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mumbai-public-subnet"
  }
}

# =========================================================
# MUMBAI INTERNET GATEWAY
# =========================================================

resource "aws_internet_gateway" "mumbai" {
  vpc_id = aws_vpc.mumbai.id

  tags = {
    Name = "mumbai-igw"
  }
}

# =========================================================
# MUMBAI ROUTE TABLE
# =========================================================

resource "aws_route_table" "mumbai" {
  vpc_id = aws_vpc.mumbai.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai.id
  }

  tags = {
    Name = "mumbai-public-route-table"
  }
}

resource "aws_route_table_association" "mumbai" {
  subnet_id      = aws_subnet.mumbai.id
  route_table_id = aws_route_table.mumbai.id
}

# =========================================================
# MUMBAI SECURITY GROUP
# =========================================================

resource "aws_security_group" "mumbai" {
  name   = "mumbai-ec2-sg"
  vpc_id = aws_vpc.mumbai.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
    Name = "mumbai-ec2-sg"
  }
}

# =========================================================
# MUMBAI EC2
# =========================================================

resource "aws_instance" "mumbai" {
  ami           = var.mumbai_ami
  instance_type = "t3.micro"

  subnet_id = aws_subnet.mumbai.id

  vpc_security_group_ids = [
    aws_security_group.mumbai.id
  ]

  associate_public_ip_address = true

  tags = {
    Name   = "mumbai-primary-server"
    Region = "Mumbai"
    Role   = "Primary"
  }
}

# =========================================================
# SINGAPORE VPC
# =========================================================

resource "aws_vpc" "singapore" {
  provider = aws.singapore

  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "singapore-dr-vpc"
    Region      = "Singapore"
    Environment = "DR"
  }
}

# =========================================================
# SINGAPORE SUBNET
# =========================================================

resource "aws_subnet" "singapore" {
  provider = aws.singapore

  vpc_id                  = aws_vpc.singapore.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "singapore-public-subnet"
  }
}

# =========================================================
# SINGAPORE INTERNET GATEWAY
# =========================================================

resource "aws_internet_gateway" "singapore" {
  provider = aws.singapore

  vpc_id = aws_vpc.singapore.id

  tags = {
    Name = "singapore-igw"
  }
}

# =========================================================
# SINGAPORE ROUTE TABLE
# =========================================================

resource "aws_route_table" "singapore" {
  provider = aws.singapore

  vpc_id = aws_vpc.singapore.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.singapore.id
  }

  tags = {
    Name = "singapore-public-route-table"
  }
}

resource "aws_route_table_association" "singapore" {
  provider = aws.singapore

  subnet_id      = aws_subnet.singapore.id
  route_table_id = aws_route_table.singapore.id
}

# =========================================================
# SINGAPORE SECURITY GROUP
# =========================================================

resource "aws_security_group" "singapore" {
  provider = aws.singapore

  name   = "singapore-ec2-sg"
  vpc_id = aws_vpc.singapore.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
    Name = "singapore-ec2-sg"
  }
}

# =========================================================
# SINGAPORE EC2
# =========================================================

resource "aws_instance" "singapore" {
  provider = aws.singapore

  ami           = var.singapore_ami
  instance_type = "t3.micro"

  subnet_id = aws_subnet.singapore.id

  vpc_security_group_ids = [
    aws_security_group.singapore.id
  ]

  associate_public_ip_address = true

  tags = {
    Name   = "singapore-dr-server"
    Region = "Singapore"
    Role   = "DR"
  }
}

# =========================================================
# VARIABLES
# =========================================================

variable "mumbai_ami" {
  description = "AMI ID available in Mumbai region"
  type        = string
}

variable "singapore_ami" {
  description = "AMI ID available in Singapore region"
  type        = string
}

# =========================================================
# OUTPUTS
# =========================================================

output "mumbai_instance_id" {
  value = aws_instance.mumbai.id
}

output "mumbai_public_ip" {
  value = aws_instance.mumbai.public_ip
}

output "singapore_instance_id" {
  value = aws_instance.singapore.id
}

output "singapore_public_ip" {
  value = aws_instance.singapore.public_ip
}