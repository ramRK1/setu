terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

# Create a VPC to launch our instances into
resource "aws_vpc" "ram-vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  
  tags = {
    Name = "ram-vpc"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "ram-igw" {
  vpc_id = aws_vpc.ram-vpc.id
}

# Grant the VPC internet access on its main route table
# resource "aws_route" "internet_access" {
#   route_table_id         = aws_vpc.ram-vpc.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.ram-igw.id
# }

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.ram-vpc.id
  tags = {
    Name = "PublicRouteTable"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ram-igw.id
  }

  depends_on = [aws_vpc.ram-vpc, aws_internet_gateway.ram-igw]
}

resource "aws_route_table_association" "PublicRouteTableAssociate" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.PublicRouteTable.id

  depends_on = [aws_subnet.public-subnet, aws_route_table.PublicRouteTable]
}


resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.ram-vpc.id
  tags = {
    Name = "PrivateRouteTable"
  }

  depends_on = [aws_vpc.ram-vpc]
}

resource "aws_route_table_association" "PrivateRouteTableAssociate1" {
  subnet_id = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.PrivateRouteTable.id

  depends_on = [aws_subnet.private-subnet1, aws_route_table.PrivateRouteTable]
}

resource "aws_route_table_association" "PrivateRouteTableAssociate2" {
  subnet_id = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.PrivateRouteTable.id

  depends_on = [aws_subnet.private-subnet2, aws_route_table.PrivateRouteTable]
}


resource "aws_eip" "nat" {
  count = 2

  vpc = true
}


# Create a pulic subnet to launch bastion
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.ram-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ram_public_subnet"
  }
  depends_on = [aws_vpc.ram-vpc]
}


# Create a private subnet to launch applications
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = aws_vpc.ram-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ram_private_subnet1"
  }
  depends_on = [aws_vpc.ram-vpc]
}

# Create a private subnet to launch applications
resource "aws_subnet" "private-subnet2" {
  vpc_id                  = aws_vpc.ram-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ram_private_subnet2"
  }
  depends_on = [aws_vpc.ram-vpc]
}


# Create a Database subnet to launch database
resource "aws_subnet" "database-subnet1" {
  vpc_id                  = aws_vpc.ram-vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ram_database_subnet1"
  }
  depends_on = [aws_vpc.ram-vpc]
}

# Create a Database subnet to launch database
resource "aws_subnet" "database-subnet2" {
  vpc_id                  = aws_vpc.ram-vpc.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ram_database_subnet2"
  }
  depends_on = [aws_vpc.ram-vpc]
}


# NAT Gateway for Application subnet
resource "aws_nat_gateway" "private-nat-1" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.private-subnet1.id

  tags = {
    Name = "Private-Subnet1-NAT-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ram-igw]
}

# NAT Gateway for Application subnet
resource "aws_nat_gateway" "private-nat-2" {
  allocation_id = aws_eip.nat[1].id
  subnet_id     = aws_subnet.private-subnet2.id

  tags = {
    Name = "Private-Subnet2-NAT-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ram-igw]
}


# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.ram-vpc.id
  tags = {
    Name = "ram-vpc_elb_sg"
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion-sg" {
  name        = "bastion_security_group"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.ram-vpc.id
  tags = {
    Name = "ram-vpc_bastion_sg"
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "public-sg" {
  name        = "public_security_group"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.ram-vpc.id
  tags = {
    Name = "ram-vpc_public-app_sg"
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/22"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private-sg" {
  name        = "private_security_group"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.ram-vpc.id
  tags = {
    Name = "ram-vpc_private-app_sg"
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/22"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database-sg" {
  name        = "database_security_group"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.ram-vpc.id
  tags = {
    Name = "ram-vpc_private-app_sg"
  }

  # SSH access from private-subnet1
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
  # SSH access from private-subnet2
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }
  # DB access from private-subnet1
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
  # DB access from private-subnet2
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }


  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "web" {
  name = "public-elb"

  subnets         = [aws_subnet.public-subnet.id]
  security_groups = [aws_security_group.elb.id]
  instances       = [aws_instance.public-app1.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = var.key_name1
  public_key = file(var.bastion_public_key_path)
}

resource "aws_key_pair" "application" {
  key_name   = var.key_name2
  public_key = file(var.application_public_key_path)
}

resource "aws_instance" "bastion" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    type = "ssh"
    # The default username for our AMI
    user = "ec2-user"
    host = self.public_ip
    private_key = file(var.bastion_private_pem)
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-033b95fb8079dc481" #var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.bastion.id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = aws_subnet.public-subnet.id

  tags = {
    Name = "Bastion"
  }

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
    ]
  }
}

resource "aws_instance" "public-app1" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
 #  connection {
 #    type = "ssh"
 #    # The default username for our AMI
 #    user = "ec2-user"
 #    host = self.private_ip
 #    private_key = file("/home/ram_kamra/app")
 #    # The connection will use the local SSH agent for authentication.
 #  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-033b95fb8079dc481" #var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.application.id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.public-sg.id]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = aws_subnet.private-subnet1.id
  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install nginx1 -y
    sudo systemctl start nginx

  EOF

  tags = {
    Name = "Public-app1"
  }  

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum update -y",
  #     "sudo amazon-linux-extras install nginx1 -y",
  #     "sudo systemctl start nginx",
  #   ]
  # }
}

resource "aws_instance" "public-app2" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
 #  connection {
 #    type = "ssh"
 #    # The default username for our AMI
 #    user = "ec2-user"
 #    host = self.private_ip
 #    private_key = file("/home/ram_kamra/app")
 #    # The connection will use the local SSH agent for authentication.
 #  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-033b95fb8079dc481" #var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.application.id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.public-sg.id]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = aws_subnet.private-subnet2.id

  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install nginx1 -y
    sudo systemctl start nginx

  EOF

  tags = {
    Name = "Public-app2"
  }


  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum update -y",
  #     "sudo amazon-linux-extras install nginx1 -y",
  #     "sudo systemctl start nginx",
  #   ]
  # }
}
