provider "aws" {
    region = "us-east-1"
    access_key = "AKIA2MVRGKFALBD5UY5Q"
    secret_key = "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"
    profile = "personal"
}



# 1.	Create VPC

resource "aws_vpc" "my_first_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "My-First-VPC"
  }
}


# 2.	Create Internet Gateway

resource "aws_internet_gateway" "my_first_internet_gateway" {
  vpc_id = aws_vpc.my_first_vpc.id

  tags = {
    Name = "My-Internet-Gateway"
  }
}


# 3.	Create Custom Route Table

resource "aws_route_table" "my_first_route_table" {
  vpc_id = aws_vpc.my_first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_first_internet_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my_first_internet_gateway.id
  }

  tags = {
    Name = "My-Route-Table"
  }
}


# 4.	Create a Subnet

resource "aws_subnet" "my_first_subnet" {
  vpc_id     = aws_vpc.my_first_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"


  tags = {
    Name = "My-Subnet"
  }
}


# 5.	Associate subnet with Route Table

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.my_first_subnet.id
  route_table_id = aws_route_table.my_first_route_table.id
}


# 6.	Create Security Group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.my_first_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


# 7.	Create Network Interface with an IP in the Subnet that was created at Step 4

resource "aws_network_interface" "my_first_nic" {
  subnet_id       = aws_subnet.my_first_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}


# 8.	Assign an elastic IP to the network interface created in Step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.my_first_nic.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [aws_internet_gateway.my_first_internet_gateway]
}


# 9.	Create Ubuntu server and Install/Enable apache2


resource "aws_instance" "my_first_web_server_using_terraform" {
    ami = "ami-0dc2d3e4c0f9ebd18"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "EC2 Tutorial"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.my_first_nic.id
    }

    # Below line will do action after launcing instance
    user_data = "${file("install_apache2.sh")}"

    tags = {
        Name = "My Web Server"
  }
}

/*
Output block helps to print any available info about resource. Output block can have only a statement so if you want multiple output, add multiple
output block
*/

output "Web_Server_IP" {
    value = aws_eip.one.public_ip
}








