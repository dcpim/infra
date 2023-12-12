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

resource "aws_internet_gateway" "dcpim_gw" {
  vpc_id = aws_vpc.dcpim_vpc.id
  tags = {
    Name = "dcpim-igw-${var.env}"
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

# S3 buckets
resource "aws_s3_bucket" "dcpim_s3_media" {
  bucket = "dcpim-media-${var.env}"
}

resource "aws_s3_bucket_versioning" "dcpim_s3_media_version" {
  bucket = aws_s3_bucket.dcpim_s3_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dcpim_s3_media_sse" {
  bucket = aws_s3_bucket.dcpim_s3_media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dcpim_s3_media_lifecycle" {
  bucket = aws_s3_bucket.dcpim_s3_media.id
  rule {
    id = "delete-expire-after-30-days"
    status = "Enabled"
    noncurrent_version_expiration {
        newer_noncurrent_versions = 0
        noncurrent_days = 30
      }
    }
  }
}
