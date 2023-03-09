data "aws_subnet" "public_subnet" {
  filter {
    name = "tag:Name"
    values = ["${var.VPC_name}-public-subnet"]
  }
}
data "aws_security_group" "public" {
    filter {
        name = "tag:Name"
        values = ["demo-public-security-group"]
  }
}

output "subnet-id" {
  value = data.aws_subnet.public_subnet.id
}

output "sg-id" {
  value = data.aws_security_group.public.id
}