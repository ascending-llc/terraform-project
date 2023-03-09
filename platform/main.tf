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

resource "aws_security_group" "vault" {
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
  
  # Open vault port
  ingress {
    from_port = 8200
    to_port = 8200
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
    Name = "demo-vault-security-group"
  }
  
}

######################################################################
# generate ssh key for vault-server instance and save to local
######################################################################
resource "tls_private_key" "vault-server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  
  key_name   = "vault_server_key"
  public_key = tls_private_key.vault-server.public_key_openssh

  provisioner "local-exec" { # Create "vault_server_key.pem" to your computer
    command = <<EOT
     echo '${tls_private_key.vault-server.private_key_pem}' >| ./vault_server_key.pem
     chmod 400 ./vault_server_key.pem
     EOT
  }
}

###############################################################
# Vault EC2 instance
###############################################################

# Create vault-server instance and launch vault
resource "aws_instance" "vault-server" {
  depends_on = [
    aws_key_pair.generated_key
  ]
  ami           = "ami-0aa7d40eeae50c9a9"
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.vault.id]
  key_name      = aws_key_pair.generated_key.key_name
  associate_public_ip_address = "true"
  user_data = <<-EOF

    #!/bin/bash
    sudo yum update -y
    cd /opt/ && sudo curl -o vault.zip  https://releases.hashicorp.com/vault/1.1.2/vault_1.1.2_linux_amd64.zip
    sudo unzip vault.zip
    sudo mv vault /usr/bin/
    sudo useradd --system --home /etc/vault.d --shell /bin/false vault
    sudo cat << EOF1 > /etc/systemd/system/vault.service
          [Unit]
          Description="HashiCorp Vault Service"
          Requires=network-online.target
          After=network-online.target
          ConditionFileNotEmpty=/etc/vault.d/vault.hcl

          [Service]
          User=vault
          Group=vault
          ProtectSystem=full
          ProtectHome=read-only
          PrivateTmp=yes
          PrivateDevices=yes
          SecureBits=keep-caps
          AmbientCapabilities=CAP_IPC_LOCK
          Capabilities=CAP_IPC_LOCK+ep
          CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
          NoNewPrivileges=yes
          ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
          ExecReload=/bin/kill --signal HUP $MAINPID
          StandardOutput=/logs/vault/output.log
          StandardError=/logs/vault/error.log
          KillMode=process
          KillSignal=SIGINT
          Restart=on-failure
          RestartSec=5
          TimeoutStopSec=30
          StartLimitIntervalSec=60
          StartLimitBurst=3
          LimitNOFILE=65536

          [Install]
          WantedBy=multi-user.target
      
    EOF1
 
    sudo mkdir /etc/vault.d
    sudo chown -R vault:vault /etc/vault.d
    sudo mkdir /vault-data
    sudo chown -R vault:vault /vault-data
    sudo mkdir -p /logs/vault/
    sudo cat  << EOF2 > /etc/vault.d/vault.hcl
          listener "tcp" {
            address     = "0.0.0.0:8200"
            tls_disable = 1
          }

          telemetry {
            statsite_address = "127.0.0.1:8125"
            disable_hostname = true
          }

          storage "file" {
            path = "/vault-data"
          }

          ui = true
    EOF2
    sudo systemctl enable vault
    sudo systemctl start vault

  EOF

  tags = {
    Name = "Vault Server"
  }
}

output "vault-server-ip" {
  value = "http://${aws_instance.vault-server.public_ip}:8200"
}


