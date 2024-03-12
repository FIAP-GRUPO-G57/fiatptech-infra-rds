# Arquivo main.tf

# Provider AWS
provider "aws" {
  region = "us-east-1" # Defina sua região AWS aqui
}

data "aws_availability_zones" "available" {}

resource "aws_db_subnet_group" "rds-fiaptech" {
  name       = "rds-prod-subnetgroup"
  subnet_ids = ["subnet-0976e430aa2640363","subnet-09e3e7080c4b28af7"]

  tags = {
    Project     = "rds"
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_security_group" "rds-fiaptech" {
  name   = "rrds-prod-securitygroup"
  vpc_id = "vpc-005f8c7fbcaf140d8"

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
  vpc_security_group_ids  = [aws_security_group.rds-fiaptech.id]

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
