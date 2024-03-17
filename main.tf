# Arquivo main.tf

# Provider AWS
provider "aws" {
  region = "us-east-1" # Defina sua região AWS aqui
}

data "aws_availability_zones" "available" {}

resource "aws_security_group" "sg-rds-fiaptech" {
  name   = "rds-prod-securitygroup"
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
  lifecycle {
  prevent_destroy = true
}
}

# Recurso RDS PostgreSQL
resource "aws_db_instance" "db-rds-fiaptech" {
  identifier              = "rds-fiaptech"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "12.5"
  instance_class          = "db.t2.micro"
  manage_master_user_password = true # Guarda o usuário e senha do banco de dados no AWS Secrets Manager
  username                = "admin"
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.sg-rds-fiaptech.id]

lifecycle {
  prevent_destroy = true
}
}

resource "aws_secretsmanager_secret_rotation" "rds-fiaptech" {
  secret_id = aws_db_instance.db-rds-fiaptech.master_user_secret[0].secret_arn

  rotation_rules {
    automatically_after_days = 30 # (Optional) # O valor padrão é 7 dias
  }
}

# Optionally fetch the secret data if attributes need to be used as inputs
# elsewhere.
data "aws_secretsmanager_secret" "rds-fiaptech" {
  arn = aws_db_instance.db-rds-fiaptech.master_user_secret[0].secret_arn
}

