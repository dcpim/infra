# Fetch master password from Secrets Manager
data "aws_secretsmanager_secret" "dcpim_secretsmanager" {
  arn = "${var.secret_arn}"
}

data "aws_secretsmanager_secret_version" "dcpim_secret" {
  secret_id = data.aws_secretsmanager_secret.dcpim_secretsmanager.id
  version_stage = "AWSCURRENT"
}

# VPC for EKS cluster
resource "aws_vpc" "dcpim_vpc" {
  cidr_block = "${var.cidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "dcpim-vpc-${var.env}"
  }
}

# Subnets
resource "aws_subnet" "dcpim_subnet_priv1" {
  vpc_id     = aws_vpc.dcpim_vpc.id
  cidr_block = "${var.cidr_priv1}"
  tags = {
    Name = "dcpim-subnet-priv1-${var.env}"
  }
}

resource "aws_subnet" "dcpim_subnet_priv2" {
  vpc_id     = aws_vpc.dcpim_vpc.id
  cidr_block = "${var.cidr_priv2}"
  tags = {
    Name = "dcpim-subnet-priv2-${var.env}"
  }
}

resource "aws_subnet" "dcpim_subnet_pub" {
  vpc_id     = aws_vpc.dcpim_vpc.id
  cidr_block = "${var.cidr_pub}"
  map_public_ip_on_launch = true
  tags = {
    Name = "dcpim-subnet-pub-${var.env}"
  }
}

# DocumentDB database
resource "aws_db_subnet_group" "dcpim_docdb_sg" {
  name = "dcpim-${var.env}-sg"
  subnet_ids = [aws_subnet.dcpim_subnet_priv1.id, aws_subnet.dcpim_subnet_priv2.id]
}

resource "aws_security_group" "dcpim_docdb_sec" {
  name = "dcpim-docdb-${var.env}-sec"
  description = "Allow local DocumentDB traffic"
  vpc_id = aws_vpc.dcpim_vpc.id

  ingress {
    description      = "All traffic from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.dcpim_vpc.cidr_block]
  }

  ingress {
    description      = "All traffic from management plane"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = "${var.ext_cidr}"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_docdb_cluster" "dcpim_docdb" {
  cluster_identifier      = "dcpim-docdb-${var.env}"
  engine                  = "docdb"
  master_username         = "dcpim"
  master_password         = data.aws_secretsmanager_secret_version.dcpim_secret.secret_string
  backup_retention_period = 1
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.dcpim_docdb_sg.id
  vpc_security_group_ids  = [aws_security_group.dcpim_docdb_sec.id]
}

resource "aws_docdb_cluster_instance" "dcpim_docdb_instance" {
  count              = 1
  identifier         = "dcpim-docdb-${var.env}-${count.index}"
  cluster_identifier = aws_docdb_cluster.dcpim_docdb.id
  instance_class     = "${var.db_instance_type}"
}

