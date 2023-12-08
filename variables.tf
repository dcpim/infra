variable "region" {
  default = "us-west-2"
}

variable "env" {
  default = "test"
}

variable "cidr" {
  default = "10.5.0.0/16"
}

variable "ext_cidr" {
  default = "172.30.0.0/16"
}

variable "cidr_priv1" {
  default = "10.5.1.0/24"
}

variable "cidr_priv2" {
  default = "10.5.2.0/24"
}

variable "cidr_pub" {
  default = "10.5.3.0/24"
}

variable "secret_arn" {
  default = "arn:aws:secretsmanager:us-west-2:310790002532:secret:dcpim-test-e6pBOP"
}

variable "db_instance_type" {
  default = "db.t4g.medium"
}
