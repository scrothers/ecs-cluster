resource "aws_vpc" "network" {
  cidr_block           = "${var.network}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  assign_generated_ipv6_cidr_block = true

  tags {
    Name        = "${var.environment}-${var.name}-vpc"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.network.id}"

  tags {
    Name        = "${var.environment}-${var.name}-igw"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.network.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name        = "${var.environment}-${var.name}-rtb"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_subnet" "cluster_subnets" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.network.id}"

  ipv6_cidr_block = "${cidrsubnet(aws_vpc.network.ipv6_cidr_block, 8, count.index + 1)}"
  cidr_block      = "${cidrsubnet(aws_vpc.network.cidr_block, 3, count.index + 1)}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags {
    Name        = "${var.environment}-${var.name}-sub-${data.aws_availability_zones.available.names[count.index]}"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.network.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1025
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 1025
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 1025
    to_port          = 65535
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "udp"
    from_port        = 1025
    to_port          = 65535
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags {
    Name        = "${var.environment}-${var.name}-sg"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.network.default_network_acl_id}"
  subnet_ids             = ["${aws_subnet.cluster_subnets.*.id}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags {
    Name        = "${var.environment}-${var.name}-nacl"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}
