######################################################################
# generate ssh key for web-server instance and save to local
######################################################################
resource "tls_private_key" "web-server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  
  key_name   = "web_server_key"
  public_key = tls_private_key.web-server.public_key_openssh

  provisioner "local-exec" { # Create "web_server_key.pem" to your computer
    command = <<EOT
     echo '${tls_private_key.web-server.private_key_pem}' >| ./web_server_key.pem
     chmod 400 ./web_server_key.pem
     EOT
  }
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
  subnet_id = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [data.aws_security_group.public.id]
  key_name      = aws_key_pair.generated_key.key_name
  associate_public_ip_address = "true"
  user_data = <<-EOF

    #!/bin/bash
    sudo yum install git -y
    sudo git clone https://github.com/daochidq/ansible_demo.git
    sudo yum update -y
    sudo amazon-linux-extras install ansible2 -y
    sudo ansible-playbook /ansible_demo/web_server.yaml --extra-vars "username=${var.username} password='${data.vault_generic_secret.read_vault.data["password"]}'"
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
