provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.environment}-private-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.environment}-public-1"
    Environment = var.environment
  }
}

resource "aws_eip" "nat_eip" {
  domain     = ["vpc"]
  depends_on = [aws_nat_gateway.nat]
  tags = {
    Name        = "${var.environment}-nat-gatway-eip"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${aws_vpc.main.tags.Name}-igw"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip
  subnet_id     = aws_subnet.public
  tags = {
    Name        = "${var.environment}-nat"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private-nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public_route" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public
}

resource "aws_route_table_association" "private_route" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "vpc_security_group" {
  name        = "${var.environment}-vpc-default-security-group"
  description = "Default Security Group for ${var.environment} VPC"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]

  ingress = {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress = {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Name        = "${var.environment}-VPC-SG"
    Environment = var.environment
  }
}