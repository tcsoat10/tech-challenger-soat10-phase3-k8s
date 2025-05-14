provider "aws" {
  region = var.aws_region 
}

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

# Buscar Security Group existente
data "aws_security_group" "existing_eks_sg" {
  filter {
    name   = "group-name"
    values = ["${var.cluster_name}-sg"]
  }
}

# Criar novo Security Group se não existir
resource "aws_security_group" "eks_sg" {
  count = length(data.aws_security_group.existing_eks_sg.id) == 0 ? 1 : 0
  
  name        = "${var.cluster_name}-sg"
  vpc_id      = data.aws_vpc.vpc.id

  # Regras de entrada
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regras de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Definir qual Security Group será usado
locals {
  security_group_id = length(data.aws_security_group.existing_eks_sg.id) == 0 ? aws_security_group.eks_sg[0].id : data.aws_security_group.existing_eks_sg.id
}

# Usar Security Group na configuração do EKS
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    security_group_ids = [local.security_group_id]
    subnet_ids         = data.aws_subnets.eks_subnets.ids
  }
}

# Definição do cluster EKS
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = var.aws_iam_role
  vpc_config {
    subnet_ids         = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.aws_region}e"]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
  access_config {
    authentication_mode = var.accessConfig
  }
}

resource "aws_eks_access_entry" "eks-access-entry" {
  cluster_name      = aws_eks_cluster.cluster.name
  principal_arn     = var.principal_arn
  kubernetes_groups = ["my-nodes-group"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks-access-policy" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = var.policy_arn
  principal_arn = var.principal_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_node_group" "eks-node" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.node_name
  node_role_arn   = var.aws_iam_role
  subnet_ids      = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.aws_region}e"]
  disk_size       = 30
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
}