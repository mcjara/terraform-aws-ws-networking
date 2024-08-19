data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

data "aws_ip_ranges" "aws-connect-ip-address-range" {
  regions  = [data.aws_region.current.name]
  services = ["EC2_INSTANCE_CONNECT"]
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"

  tags = {
    Name = var.instance_name
  }
}

data "aws_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

# Remove all inbound rules from the default security group
resource "aws_security_group_rule" "default_inbound" {
  security_group_id = data.aws_security_group.default.id
  type              = "ingress"
  protocol          = "-1"  # -1 means all protocols
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle {
    create_before_destroy = true
  }
}

# Remove all outbound rules from the default security group
resource "aws_security_group_rule" "default_outbound" {
  security_group_id = data.aws_security_group.default.id
  type              = "egress"
  protocol          = "-1"  # -1 means all protocols
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = var.logs_bucket_arn
  log_format           = "${var.logs_bucket_arn}/flow-logs/"

  destination_options {
    per_hour_partition = true
  }
}
 */

resource "aws_subnet" "public-subnets" {
  count                   = var.VPC_PUBLIC_SUBNET_COUNT
  cidr_block              = var.VPC_PUBLIC_SUBNETS_CIDR_BLOCK[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.instance_name}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private-subnets" {
  count                   = var.VPC_PRIVATE_SUBNET_COUNT
  cidr_block              = var.VPC_PRIVATE_SUBNETS_CIDR_BLOCK[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.instance_name}-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.instance_name}-igw"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnets[0].id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.instance_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.VPC_PUBLIC_SUBNET_COUNT
  subnet_id      = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.instance_name}-private-rt"
  }
}

resource "aws_route_table_association" "rt-private-subnets" {
  count          = var.VPC_PRIVATE_SUBNET_COUNT
  subnet_id      = aws_subnet.private-subnets[count.index].id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-lb-sec-grp"
  }
}

resource "aws_security_group" "ec2_instance_connect" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.aws-connect-ip-address-range.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-ec2-instance-connect-sec-grp"
  }
}

resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect" {
  subnet_id = aws_subnet.private-subnets[0].id

  security_group_ids = [
    aws_security_group.ec2_instance_connect.id,
  ]
}

resource "aws_security_group" "vm" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instance_connect.id]
  }

  dynamic "ingress" {
    for_each = var.vm_ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.lb.id]
    }
  }

  tags = {
    Name = "${var.instance_name}-vm-sec-grp"
  }
}

resource "aws_security_group" "database" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vm.id]
  }

  tags = {
    Name = "${var.instance_name}-database-sec-grp"
  }
}

resource "aws_security_group" "cache" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = var.cache_port
    to_port         = var.cache_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vm.id]
  }

  tags = {
    Name = "${var.instance_name}-cache-sec-grp"
  }
}

resource "aws_security_group" "efs" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = var.efs_port
    to_port         = var.efs_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vm.id]
  }

  tags = {
    Name = "${var.instance_name}-efs-sec-grp"
  }
}
