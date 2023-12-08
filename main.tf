# Fetch master password from Secrets Manager
data "aws_secretsmanager_secret" "dcpim_secretsmanager" {
  arn = "${var.secret_arn}"
}

data "aws_secretsmanager_secret_version" "dcpim_secret" {
  secret_id = aws_secretsmanager_secret.dcpim_secretsmanager.id
  version_stage = "AWSCURRENT"
}

# VPC for EKS cluster
resource "aws_vpc" "dcpim_vpc" {
  cidr_block = "${var.cidr}"
  instance_tenancy = "default"
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

resource "aws_docdb_cluster" "dcpim_docdb" {
  cluster_identifier      = "dcpim-docdb-${var.env}"
  engine                  = "docdb"
  master_username         = "dcpim"
  master_password         = aws_secretsmanager_secret_version.dcpim_secret.secret_string
  backup_retention_period = 1
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = data.aws_db_subnet_group.dcpim_docdb_sg.id
}

resource "aws_docdb_cluster_instance" "dcpim_docdb_instance" {
  count              = 1
  identifier         = "dcpim-docdb-${var.env}-${count.index}"
  cluster_identifier = aws_docdb_cluster.dcpim_docdb.id
  instance_class     = "${var.db_instance_type}"
}
