# ========== (ru-spb) ==========

resource "aws_vpc" "vpc_region2" {
  provider   = aws.region2
  cidr_block = "172.21.0.0/25"  # Другая подсеть для второго региона
  enable_dns_support = true

  tags = {
    Name = "terraform-${var.region[1]}"
  }
}

resource "aws_internet_gateway" "igw_region2" {
  provider = aws.region2
  vpc_id   = aws_vpc.vpc_region2.id

  tags = {
    Name = "tf-igw-${var.region[1]}"
  }
}

resource "aws_default_route_table" "main_region2" {
  provider               = aws.region2
  default_route_table_id = aws_vpc.vpc_region2.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_region2.id
  }

  tags = {
    Name = "main-route-table-${var.region[1]}"
  }
}

resource "aws_subnet" "subnet_region2" {
  provider          = aws.region2
  availability_zone = var.availability_zones[var.region[1]]  # Используйте соответствующую зону для второго региона
  cidr_block        = "172.21.0.0/26"
  vpc_id            = aws_vpc.vpc_region2.id

  tags = {
    Name = "Subnet-${var.region[1]}"
  }
}

resource "aws_key_pair" "pubkey_region2" {
  provider   = aws.region2
  key_name   = "${var.pubkey_name}-${var.region[1]}"
  public_key = var.public_key
}

resource "aws_eip" "eip_region2" {
  provider   = aws.region2
  count      = var.eips_count
  vpc        = true
  depends_on = [aws_vpc.vpc_region2]

  tags = {
    Name = "${var.hostnames[0]}-${var.region[1]}"
  }
}

resource "aws_security_group" "ext_region2" {
  provider    = aws.region2
  vpc_id      = aws_vpc.vpc_region2.id
  name        = "ext-${var.region[1]}"
  description = "External SG ${var.region[1]}"

  dynamic "ingress" {
    iterator = port
    for_each = var.allow_tcp_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_ip
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "External SG ${var.region[1]}"
  }
}

resource "aws_security_group" "int_region2" {
  provider    = aws.region2
  vpc_id      = aws_vpc.vpc_region2.id
  name        = "int-${var.region[1]}"
  description = "Internal SG ${var.region[1]}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Internal SG ${var.region[1]}"
  }
}

resource "aws_instance" "vm_region2" {
  provider                   = aws.region2
  count                      = var.instances_per_region
  ami                        = var.vm_template[1]
  instance_type              = var.vm_instance_type
  key_name                   = aws_key_pair.pubkey_region2.key_name
  availability_zone          = var.availability_zones[var.region[1]]
  subnet_id                  = aws_subnet.subnet_region2.id
  vpc_security_group_ids     = [aws_security_group.int_region2.id, aws_security_group.ext_region2.id]

  tags = {
    Name = "VM-${var.region[1]}-${count.index}"
  }

  ebs_block_device {
    delete_on_termination = true
    device_name           = "disk1"
    volume_type           = var.vm_volume_type
    volume_size           = var.vm_volume_size

    tags = {
      Name = "Disk-${var.region[1]}-${count.index}"
    }
  }

  depends_on = [
    aws_subnet.subnet_region2,
    aws_security_group.int_region2,
    aws_key_pair.pubkey_region2,
  ]
}

resource "aws_eip_association" "eip_assoc_region2" {
  provider      = aws.region2
  count         = min(var.eips_count, var.instances_per_region)
  instance_id   = aws_instance.vm_region2[count.index].id
  allocation_id = aws_eip.eip_region2[count.index].id
  depends_on    = [aws_internet_gateway.igw_region2]
}