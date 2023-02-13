###############################################################
# VPC with 1 public & 1 private subnet
###############################################################
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = var.VPC_block
  instance_tenancy = "default"

  tags = {
    Name = var.VPC_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_block
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.VPC_name}-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_block
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.VPC_name}-private-subnet"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

# public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "public subnets"
    Network = "public"
  }
}

# Public Subnet RouteTable Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name    = "private subnets"
    Network = "private"
  }
}

# Private Subnet RouteTable Association
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

###############################################################
# Security Groups
###############################################################
resource "aws_security_group" "public" {
  vpc_id = aws_vpc.main_vpc.id

  # Open HTTP port
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Open HTTPS port
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Open SSH port
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-public-security-group"
  }
  
}

resource "aws_security_group" "private" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [ aws_security_group.public.id ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-private-security-group"
  }
}


######################################################################
# Provision Vault
######################################################################
# Read the secret from vault server
data "vault_generic_secret" "read_vault" {
  path = "kv/demo"
}
output "secrets" {
  value     = data.vault_generic_secret.read_vault.data["data"]
  sensitive = true
  
}

###############################################################
# EC2 instances
###############################################################

# Create web-server instance and launch ansible
resource "aws_instance" "web-server" {
  depends_on = [
    aws_key_pair.generated_key
  ]
  ami           = "ami-0aa7d40eeae50c9a9"
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public.id]
  key_name      = aws_key_pair.generated_key.key_name
  associate_public_ip_address = "true"
  user_data = <<-EOF

    #!/bin/bash
    sudo yum install git -y
    sudo git clone https://github.com/daochidq/ansible_demo.git
    sudo yum update -y
    sudo amazon-linux-extras install ansible2 -y
    sudo ansible-playbook /ansible_demo/web_server.yaml --extra-vars "valut_data='${data.vault_generic_secret.read_vault.data["data"]}'"
  EOF

  tags = {
    Name = "Web Server"
  }
}


# resource "aws_instance" "database" {
#   ami           = "ami-0aa7d40eeae50c9a9"
#   instance_type = var.instance_type
#   subnet_id = aws_subnet.private_subnet.id
#   vpc_security_group_ids = [aws_security_group.private.id]
#   tags = {
#     Name = "Database"
#   }
# }

output "web-server-ip" {
  value = aws_instance.web-server.public_ip
}

######################################################################
# generate ssh key for web-server instance and save to local
######################################################################
resource "tls_private_key" "web-server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name   = "web-server-ssh-key"
  public_key = tls_private_key.web-server.public_key_openssh

  provisioner "local-exec" { # Create "web_server_key.pem" to your computer
    command = <<EOT
     echo '${tls_private_key.web-server.private_key_pem}' > ./web_server_key.pem
     chmod 400 ./web_server_key.pem
     EOT
  }
}

output "private_key" {
  value     = tls_private_key.web-server.private_key_pem
  sensitive = true
}
