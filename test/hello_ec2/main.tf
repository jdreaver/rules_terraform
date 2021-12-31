provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    # TODO: Share S3 bucket and dynamodb table values with other modules
    bucket         = "jdreaver-rules-terraform-test-state"
    key            = "hello_ec2"
    region         = "us-west-2"
    dynamodb_table = "terraform-statelock"
  }
}

# TODO: Generate this reference to remote state in bazel so we know
data "terraform_remote_state" "vpc" {
  backend = "s3"
  # TODO: DRY these values with vpc modeula
  config = {
    bucket = "jdreaver-rules-terraform-test-state"
    key    = "vpc"
    region = "us-west-2"
  }
}

resource "aws_security_group" "hello_ec2" {
  name        = "rules_terraform_hello_ec2"
  description = "hello_ec2 group for rules_terraform testing"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "hello_ec2" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  availability_zone = data.terraform_remote_state.vpc.outputs.public_subnet_az
  key_name          = aws_key_pair.hello_ec2.key_name

  #   user_data = <<-EOF
  #                 #!/bin/bash
  #                 sudo apt update -y
  #                 sudo apt install apache2 -y
  #                 sudo systemctl start apache2
  #                 sudo bash -c 'echo your very first web server > /var/www/html/index.html'
  #                 EOF
  tags = {
    Name = "rules-terraform-test-hello-ec2"
  }

  network_interface {
    network_interface_id = aws_network_interface.hello_ec2.id
    device_index         = 0
  }
}

resource "aws_key_pair" "hello_ec2" {
  key_name   = "hello-ec2-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "aws_network_interface" "hello_ec2" {
  subnet_id = data.terraform_remote_state.vpc.outputs.public_subnet_id
  security_groups = [
    aws_security_group.hello_ec2.id
  ]

  tags = {
    Name = "rules-terraform-test-hello-ec2"
  }
}

resource "aws_eip" "hello_ec2" {
  vpc               = true
  network_interface = aws_network_interface.hello_ec2.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

output "server_public_ip" {
  value = aws_eip.hello_ec2.public_ip
}
