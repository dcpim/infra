resource "aws_vpc" "eks_vpc" {
  cidr_block = "${var.cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "eks_vpc"
  }
}


