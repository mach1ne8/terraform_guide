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
  availability_zone = var.az                     # Зона доступности из переменной
  cidr_block        = "172.20.0.0/26"           # IP-адреса подсети
  vpc_id            = aws_vpc.vpc.id             # В созданном VPC
  depends_on        = [aws_vpc.vpc]              # Создаём после VPC

  tags = {
    Name = "Subnet in ${var.az} for ${lookup(aws_vpc.vpc.tags, "Name")}"
  }
}

resource "aws_key_pair" "pubkey" {
  key_name   = var.pubkey_name                   # Имя SSH-ключа
  public_key = var.public_key                    # Содержимое публичного ключа
}

resource "aws_eip" "eips" {
  count      = var.eips_count                    # Количество EIP из переменной
  vpc        = true                              # В рамках VPC
  depends_on = [aws_vpc.vpc]                     # После создания VPC

  tags = {
    Name = var.hostnames[count.index]            # Имя из массива hostnames
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
  count           = var.vms_count                # Количество интерфейсов
  subnet_id       = aws_subnet.subnet.id        # В созданной подсети
  description     = "Network interface ${count.index}"
  security_groups = [aws_security_group.int.id] # Внутренняя группа безопасности
}

resource "aws_instance" "vms" {
  count         = var.vms_count                  # Количество ВМ
  ami           = var.vm_template                # ID образа
  instance_type = var.vm_instance_type          # Тип экземпляра
  key_name      = var.pubkey_name                # SSH-ключ
  monitoring    = true                           # Включить мониторинг

  network_interface {                            # Кастомный сетевой интерфейс
    network_interface_id = aws_network_interface.interfaces[count.index].id
    device_index         = 0  
  }

  depends_on = [
    aws_subnet.subnet,
    aws_security_group.int,
    aws_key_pair.pubkey,
    aws_network_interface.interfaces,
  ]

  tags = {
    Name = "VM for ${var.hostnames[count.index]}"
  }

  ebs_block_device {                             # Дополнительный диск
    delete_on_termination = true                 # Удалять с ВМ
    device_name           = "disk1"              # Имя устройства
    volume_type           = var.vm_volume_type   # Тип диска
    volume_size           = var.vm_volume_size   # Размер в ГБ

    tags = {
      Name = "Disk for ${var.hostnames[count.index]}"
    }
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.ext.id              # Внешняя группа безопасности
  network_interface_id = aws_instance.vms[0].primary_network_interface_id  # К первой ВМ
  depends_on = [
    aws_instance.vms,
    aws_security_group.ext,
  ]
}

resource "aws_eip_association" "eips_association" {
  # Назначение EIP возможно только после присоединения интернет-шлюза к VPC
  depends_on = [aws_internet_gateway.example]
  # Получаем количество созданных EIP
  count         = var.eips_count                
  # и по очереди назначаем каждый из них экземплярам
  instance_id   = element(aws_instance.vms.*.id, count.index)
  allocation_id = element(aws_eip.eips.*.id, count.index)
}