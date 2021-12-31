provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    # TODO: Share S3 bucket and dynamodb table values with other modules
    bucket         = "jdreaver-rules-terraform-test-state"
    key            = "vpc"
    region         = "us-west-2"
    dynamodb_table = "terraform-statelock"
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.25.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "rules-terraform-test-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.25.0.0/24"

  tags = {
    Name = "rules-terraform-test-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rules-terraform-test-igw"
  }
}

resource "aws_default_route_table" "main_default" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}
