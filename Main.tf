terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  access_key = "AKIA6PME6FIHRNIZAZMQ"
  secret_key = "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"
}

#create a Virual Private Network - VPC
resource "aws_vpc" "terra_prj1" {
  cidr_block = "10.0.0.0/16"
}

#Create an intetnet gateway
resource "aws_internet_gateway" "terra_prj1_gateway" {
  vpc_id = aws_vpc.terra_prj1.id
}

#create a custom route table
resource "aws_route_table" "terra_prj1_custom_route" {
  vpc_id = aws_vpc.terra_prj1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_prj1_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.terra_prj1_gateway.id
  }

  tags = {
    Name = "example"
  }
}

#Create a subnet
resource "aws_subnet" "terra_prj1_subnet" {
  vpc_id = aws_vpc.terra_prj1.id
  cidr_block = "10.0.0.0/16"
  availability_zone = "eu-north-1a"
}

#Associate the subnet to custom route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.terra_prj1_subnet.id
  route_table_id = aws_route_table.terra_prj1_custom_route.id
}

#Create a security group 
resource "aws_security_group" "terra_prj1_sec_grp" {
  name        = "allow_terra_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.terra_prj1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#create a network interface
resource "aws_network_interface" "terra_prj1_sec_network_interface" {
  subnet_id       = aws_subnet.terra_prj1_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.terra_prj1_sec_grp.id]
}

#Assign a publc IP (Elastic IP)
resource "aws_eip" "terra_prj1_sec_elasticIP" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.terra_prj1_sec_network_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.terra_prj1_gateway]
}

#Create an EC2 Instance
resource "aws_instance" "terra_prj1_sec_ec2" {
  ami = "ami-01d565a5f2da42e6f"
  instance_type = "t3.micro"
  availability_zone = "eu-north-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.terra_prj1_sec_network_interface.id
  }
  user_data = file("/Users/inshafmohamed/Downloads/Terraform_Project/userdata.sh")        
}
