#My Project VPC having my subnets and instances I need for the voting application
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
 
  tags = {
    Name = "TavleenProjectVPC"
  }
}
#Defining public subnet here that will have EC2 instance with voting and result app. Defining internet gateway, routing table, EC2 instance and its security group
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
 #availability_zone       = "us-east-1a"

  tags = {
    Name = "TavleenProjectPublicSubnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "TavleenProjectInternetGateway"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "TavleenProjectPublicRouteTable"
  }
}
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
#Public Subnet EC2 instance and its security group
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow HTTP, HTTPS, and SSH from my ip"
  vpc_id      = aws_vpc.my_vpc.id

  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTPS from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH from anywhere
  }

  # Outbound (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "frontend-sg" }
}
#EC2 instance is as follows
resource "aws_instance" "frontend" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true  # Important! Makes it accessible from internet
  key_name               = var.key_pair_name

  tags = {
    Name = "frontend-server-project-tavleen"
  }
}

# Private app subnet is defined below that will have redis and worker app. Also defined EC2 instance, route table and its association. No NAT needed.
resource "aws_subnet" "private_worker" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
}
resource "aws_route_table" "private_worker" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-worker-route-table"
  }
}
resource "aws_route_table_association" "private_app_assoc" {
  subnet_id      = aws_subnet.private_worker.id
  route_table_id = aws_route_table.private_worker.id
}
#Below is security group and associated EC2 instance in this private subnet 1. Needs traffic flow only to and from within VPC i.e other subnets
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow traffic from within VPC only"
  vpc_id      = aws_vpc.my_vpc.id

   # Allow ping (ICMP) from within the VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }
  # Inbound rules: allow traffic from the VPC CIDR to redis port 6379
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]  # allow all ports from VPC
  }

  # Outbound rules: allow traffic only to postgres in another private subnet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg-project-tavleen"
  }
}

resource "aws_instance" "private_ec2_worker" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_worker.id     # private subnet
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_pair_name
  # No public IP
  associate_public_ip_address = false

  tags = {
    Name = "private-ec2-worker"
  }
}

# Private DB subnet having postgres sql EC2 instance. EC2 instance, route table and its association defined here. No NAT needed as only internet subnet commuication.
resource "aws_subnet" "private_db" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
}
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.my_vpc.id
  
  tags = {
    Name = "private-db-route-table"
  }
}
resource "aws_route_table_association" "private_db_assoc" {
  subnet_id = aws_subnet.private_db.id
  route_table_id = aws_route_table.private_db.id
}
resource "aws_security_group" "private_sg_db" {
  name        = "private-sg-db"
  description = "Allow traffic from within VPC only"
  vpc_id      = aws_vpc.my_vpc.id

    # Allow ping (ICMP) from within the VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }
  # Inbound rules: allow traffic from the VPC CIDR to redis port 6379
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]  # allow all ports from VPC
  }

  # Outbound rules: allow traffic only to postgres in another private subnet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg-project-tavleen-db"
  }
}
 
resource "aws_instance" "private_ec2_db" {
  ami			= "ami-0ecb62995f68bb549"
  instance_type		= "t3.micro"
  subnet_id		= aws_subnet.private_db.id
  vpc_security_group_ids =[aws_security_group.private_sg_db.id]
  key_name               = var.key_pair_name
# No public IP
  associate_public_ip_address = false

  tags = {
    Name = "private-ec2"
  }
}
