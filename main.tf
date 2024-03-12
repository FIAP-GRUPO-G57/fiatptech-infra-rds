# Arquivo main.tf

# Provider AWS
provider "aws" {
  region = "us-east-1" # Defina sua região AWS aqui
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "rds-prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project     = "rds"
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_db_subnet_group" "rds-fiaptech" {
  name       = "rds-prod-subnetgroup"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Project     = "rds"
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_security_group" "rds-fiaptech" {
  name   = "rms-prod-securitygroup"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = "rms"
    Terraform   = "true"
    Environment = "prod"
  }
}
# Recurso Security Group
resource "aws_security_group" "db_security_group" {
  name        = "db-security-group"
  description = "Security group for RDS PostgreSQL"

  vpc_id = module.vpc.vpc_id

  # Defina as regras de entrada e saída conforme necessário
  # Exemplo de regra permitindo conexões na porta 5432 (PostgreSQL)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Recurso RDS PostgreSQL
resource "aws_db_instance" "rds-fiaptech" {
  identifier              = "rds-fiaptech"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "12.5"
  instance_class          = "db.t2.micro"
  manage_master_user_password = true # Guarda o usuário e senha do banco de dados no AWS Secrets Manager
  username                = "admin"
  publicly_accessible     = false
  db_subnet_group_name    = "default" # Selecione o grupo de subnets correto
  vpc_security_group_ids  = [aws_security_group.db_security_group.id]

}

resource "aws_secretsmanager_secret_rotation" "rds-fiaptech" {
  secret_id = aws_db_instance.rds-fiaptech.master_user_secret[0].secret_arn

  rotation_rules {
    automatically_after_days = 30 # (Optional) # O valor padrão é 7 dias
  }
}

# Optionally fetch the secret data if attributes need to be used as inputs
# elsewhere.
data "aws_secretsmanager_secret" "rds-fiaptech" {
  arn = aws_db_instance.rds-fiaptech.master_user_secret[0].secret_arn
}
