resource "aws_vpc" "vpc" {
  cidr_block         = "172.20.0.0/25"          # IP-адрес сети VPC в нотации CIDR
  enable_dns_support = true                      # Поддержка DNS-серверов К2 Облака

  tags = {
    Name = "terraform"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.vpc.id                        # Присоединяем к VPC

  tags = {
    Name = "tf-igw"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id  # Основная таблица маршрутизации VPC

  route {
    cidr_block = "0.0.0.0/0"                     # Маршрут по умолчанию
    gateway_id = aws_internet_gateway.example.id  # Через интернет-шлюз
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_subnet" "subnet" {
  for_each          = { for idx, az in var.az : az => idx }
  availability_zone = each.key
  cidr_block        = var.subnet_cidrs[each.value]
  vpc_id            = aws_vpc.vpc.id             # В созданном VPC
  depends_on        = [aws_vpc.vpc]              # Создаём после VPC

  tags = {
    Name = "Subnet-${each.key}"
  }
}

resource "aws_key_pair" "pubkey" {
  key_name   = var.pubkey_name                   # Имя SSH-ключа
  public_key = var.public_key                    # Содержимое публичного ключа
}

resource "aws_eip" "eips" {
  for_each   = local.vm_map  # EIP для каждой ВМ
  vpc        = true                              # В рамках VPC
  depends_on = [aws_vpc.vpc]                     # После создания VPC

  tags = {
    Name = "EIP-${each.key}"  # each.key теперь название зоны
  }
}

resource "aws_security_group" "ext" {
  vpc_id      = aws_vpc.vpc.id                   # В созданном VPC
  name        = "ext"                            # Имя группы безопасности
  description = "External SG"                    # Описание

  dynamic "ingress" {                            # Динамические входящие правила
    iterator = port
    for_each = var.allow_tcp_ports               # Перебор портов из переменной
    content {
      from_port   = port.value                   # Порт из списка
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_ip               # IP-адреса источников
    }
  }

  egress {                                       # Исходящий трафик
    from_port   = 0
    to_port     = 0
    protocol    = "-1"                           # Все протоколы
    cidr_blocks = ["0.0.0.0/0"]                 # Во все сети
  }

  depends_on = [aws_vpc.vpc]

  tags = {
    Name = "External SG"
  }
}

resource "aws_security_group" "int" {
  vpc_id      = aws_vpc.vpc.id                   # В созданном VPC
  name        = "int"                            # Внутренняя группа
  description = "Internal SG"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true                             # Трафик внутри группы
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.vpc]

  tags = {
    Name = "Internal SG"
  }
}

resource "aws_network_interface" "interfaces" {
  for_each        = local.vm_map
  subnet_id       = aws_subnet.subnet[each.value.az_name].id
  description    = "Network interface in ${each.key}"
  security_groups = [aws_security_group.int.id] # Внутренняя группа безопасности
}

resource "aws_instance" "vms" {
  for_each      = local.vm_map

  ami           = var.vm_template                # ID образа
  instance_type = var.vm_instance_type          # Тип экземпляра
  key_name      = var.pubkey_name                # SSH-ключ
  monitoring    = true                           # Включить мониторинг

   network_interface {
    network_interface_id = aws_network_interface.interfaces[each.key].id
    device_index         = 0
  }

  #   availability_zone = each.key
  # subnet_id         = aws_subnet.subnet[each.key].id

  tags = {
    Name = "VM-${each.key}"
  }

  ebs_block_device {                             # Дополнительный диск
    delete_on_termination = true                 # Удалять с ВМ
    device_name           = "disk1"              # Имя устройства
    volume_type           = var.vm_volume_type   # Тип диска
    volume_size           = var.vm_volume_size   # Размер в ГБ

    tags = {
      Name = "Disk-${each.key}"
    }
  }
   depends_on = [
    aws_subnet.subnet,
    aws_security_group.int,
    aws_key_pair.pubkey,
    aws_network_interface.interfaces,
  ]
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
    for_each            = aws_instance.vms
  security_group_id    = aws_security_group.ext.id              # Внешняя группа безопасности
  network_interface_id = each.value.primary_network_interface_id
  depends_on = [
    aws_instance.vms,
    aws_security_group.ext,
  ]
}

resource "aws_eip_association" "eips_association" {
  for_each      = aws_eip.eips
  instance_id   = aws_instance.vms[each.key].id   # each.key — ключ из aws_eip.eips, должен совпадать с ключом aws_instance.vms
  allocation_id = each.value.id
  depends_on    = [aws_internet_gateway.example]
}