provider "aws" {
   region = var.aws_region
}

locals {
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr = "10.0.0.0/16"

  database_subnets = ["10.0.2.0/24", "10.0.3.0/24"]
  elasticache_subnets = ["10.0.201.0/24", "10.0.202.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "itra-project-vpc"
  cidr = local.cidr

  azs = local.azs

  # private subnets for RDS
  # need at least 2 subnets
  database_subnets = local.database_subnets

  # private subnets for Cache
  elasticache_subnets = local.elasticache_subnets

  # public for web
  public_subnets = local.public_subnets
  enable_nat_gateway = true
}

resource "aws_security_group" "web_sg" {
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "web_allow_all_out" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.web_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_allow_ssh_in" {
  type              = "ingress"
  to_port           = 22
  protocol          = "tcp"
  from_port         = 22
  security_group_id = aws_security_group.web_sg.id
  cidr_blocks       = concat(var.ip_whitelist, local.public_subnets)
}

resource "aws_security_group_rule" "web_allow_http_in" {
  type              = "ingress"
  to_port           = 80
  protocol          = "tcp"
  from_port         = 80
  security_group_id = aws_security_group.web_sg.id
  cidr_blocks       = concat(var.ip_whitelist, local.public_subnets)
}

resource "aws_security_group_rule" "web_allow_https_in" {
  type              = "ingress"
  to_port           = 443
  protocol          = "tcp"
  from_port         = 443
  security_group_id = aws_security_group.web_sg.id
  cidr_blocks       = concat(var.ip_whitelist, local.public_subnets)
}

resource "aws_security_group" "elb_sg" {
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "elb_allow_all_out" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.elb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb_allow_http_in" {
  type              = "ingress"
  to_port           = 80
  protocol          = "tcp"
  from_port         = 80
  security_group_id = aws_security_group.elb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb_allow_https_in" {
  type              = "ingress"
  to_port           = 443
  protocol          = "tcp"
  from_port         = 443
  security_group_id = aws_security_group.elb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "db_sg" {
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "db_allow_all_out" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.db_sg.id
  cidr_blocks       = local.public_subnets
}

resource "aws_security_group_rule" "db_allow_postgres_in" {
  type              = "ingress"
  to_port           = 5432
  protocol          = "tcp"
  from_port         = 5432
  security_group_id = aws_security_group.db_sg.id
  cidr_blocks       = local.public_subnets
}

resource "aws_security_group" "cache_sg" {
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "cache_allow_all_out" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.cache_sg.id
  cidr_blocks       = local.public_subnets
}

resource "aws_security_group_rule" "cache_allow_redis_in" {
  type              = "ingress"
  to_port           = 6379
  protocol          = "tcp"
  from_port         = 6379
  security_group_id = aws_security_group.cache_sg.id
  cidr_blocks       = local.public_subnets
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  filename          = "itra-web-key.pem"
  sensitive_content = tls_private_key.key.private_key_pem
  file_permission   = "0400"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "itra-web-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_instance" "web" {
  count = 2

  ami = "ami-0453cb7b5f2b7fca2"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id = module.vpc.public_subnets[count.index]

  key_name = aws_key_pair.key_pair.key_name

  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = "./${aws_key_pair.key_pair.key_name}.pem"
    destination = "/home/ec2-user/${aws_key_pair.key_pair.key_name}.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${aws_key_pair.key_pair.key_name}.pem")
      host        = self.public_ip
    }
  }

  # chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 ~/${aws_key_pair.key_pair.key_name}.pem"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${aws_key_pair.key_pair.key_name}.pem")
      host        = self.public_ip
    }
  }

  # Install nginx
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y postgresql",
      "sudo amazon-linux-extras install nginx1 redis6 -y",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${aws_key_pair.key_pair.key_name}.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_elb" "web-elb" {

  name = "web-elb"
  subnets = module.vpc.public_subnets

  internal = false

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = aws_instance.web[*].id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = [aws_security_group.elb_sg.id]

}

resource "aws_db_instance" "web-db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "9.6"
  instance_class       = "db.t2.micro"
  name                 = "itra"
  username             = "itra_user"
  password             = "foobarbaz"
  skip_final_snapshot  = true

  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_elasticache_cluster" "web-cache" {
  cluster_id           = "web-cache"
  engine               = "redis"
  engine_version       = "3.2.10"

  port                 = 6379

  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1

  security_group_ids = [aws_security_group.cache_sg.id]
  subnet_group_name = module.vpc.elasticache_subnet_group_name
}
