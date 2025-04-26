provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "trial-vpc"
  }
}

resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my_internet_gateway"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet2"
  }
}

resource "aws_network_acl" "private_subnet_acl" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "Network-acl-subnet2"
  }

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "private_acl_association" {
  subnet_id      = aws_subnet.private_subnet2.id
  network_acl_id = aws_network_acl.private_subnet_acl.id
}

resource "aws_network_acl" "public_subnet_acl" {
  vpc_id = aws_vpc.my-vpc.id

  #allow all traffic
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Network-ACL-for-subnet-1"
  }
}

#associate
resource "aws_network_acl_association" "public_acl_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  network_acl_id = aws_network_acl.public_subnet_acl.id
}

resource "aws_route_table" "route_table1_ig" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "route_table_ineternet_gateway"
  }
}

resource "aws_route_table_association" "aws_route_table_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.route_table1_ig.id
}

#elastic IP
resource "aws_eip" "Elastic_IP_Nat_gw" {
  domain = "vpc"
  tags = {
    Name = "Elastic_IP_Nat_gw"
  }
}

#Create Nat gw

resource "aws_nat_gateway" "nat_gateway_my_vpc" {
  allocation_id = aws_eip.Elastic_IP_Nat_gw.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "Nat_Gateway_my_vpc"
  }
}

resource "aws_route_table" "route_table2_Nat_gw_private_subnet" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block     = "10.0.1.0/24"
    nat_gateway_id = aws_nat_gateway.nat_gateway_my_vpc.id
  }
  tags = {
    Name = "route_table_NAT_gateway_private_subnet"
  }
}

resource "aws_route_table_association" "aws_route_table_nat_gw_private_subnet" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.route_table2_Nat_gw_private_subnet.id
}

data "aws_ami" "ami-name" {
  most_recent = true
  owners      = ["amazon"]
}

output "aws-ami-name" {
  value = data.aws_ami.ami-name
}

resource "aws_security_group" "sg-name" {
  name   = "my-sg"
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my-new-sg"
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my-new-ec2" {

  ami           = var.ami
  instance_type = var.ec2_type
  subnet_id     = aws_subnet.private_subnet2.id

  vpc_security_group_ids = [aws_security_group.sg-name.id]

}