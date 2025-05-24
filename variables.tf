variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "soat10tc-cluster-eks"
}

variable "vpc_cidr_block" {
  default = ["172.31.0.0/16"]
}

variable "aws_iam_role" {
  default = "arn:aws:iam::414132512745:role/LabRole"
}

variable "accessConfig" {
  default = "API_AND_CONFIG_MAP"
}

variable "node_name" {
  default = "my-nodes-group"
}

variable "principal_arn" {
  default = "arn:aws:iam::414132512745:role/voclabs"
}

variable "policy_arn" {
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

variable "instance_type" {
  default = "t3.micro"
}