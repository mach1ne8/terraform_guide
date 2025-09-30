variable "secret_key" {
  description = "secrey_key"
  sensitive = true                               # Скрыт в terraform.tfvars
}

variable "access_key" {
  description = "access_key"  
  sensitive = true                               # Скрыт в terraform.tfvars
}

variable "region" {
  description = "region"
  type = list(string)
  default     = ["ru-msk", "ru-spb"]
}

variable "instances_per_region" {
  description = "Количество ВМ в каждом регионе"
  type        = number
  default     = 1
}

variable "public_key" {
  description = "pub_key"
  sensitive = true                               # Скрыт в terraform.tfvars SSH публичный ключ
}

variable "pubkey_name" {
  description = "pubkey_name"
  default = "terra"                              # Имя SSH-ключа в облаке
}

variable "availability_zones" {
  description = "Зоны доступности для каждого региона"
  type        = map(string)
  default = {
    "ru-msk" = "ru-msk-comp1p"  # Для региона Москва
    "ru-spb" = "ru-spb-a"     # Для региона СПб
  }
}

variable "eips_count" {
  description = "Enter the number of Elastic IP addresses to create (1 by default)"
  default     = 1                               # Количество публичных IP
}

variable "vms_count" {
  description = "Enter the number of virtual machines to create (2 by default)"
  default     = 1                               # Количество виртуальных машин
}

variable "hostnames" {
  description = "hostnames"
  type = list(string)
  default = ["terraform"]                       # Список имен хостов для ВМ
}

variable "allow_tcp_ports" {
  description = "Enter TCP ports to allow connections to (22, 80, 443 by default)"
  default     = [22]                            # Разрешенные TCP порты
}

variable "vm_template" {
  description = "Enter the template ID to create a VM"
  type = list(string)
  default     = ["cmi-C45746AF","cmi-BF8A3F7F"]               # ID образа K2 Cloud
}

variable "vm_instance_type" {
  description = "Enter the instance type for a VM (m5.2small by default)"
  default     = "m5.large"                      # Тип инстанса
}

variable "vm_volume_type" {
  description = "Enter the volume type for VM disks (gp2 by default)"
  default     = "gp2"                           # Тип диска 
}

variable "vm_volume_size" {
  # Размер по умолчанию и шаг наращивания указаны для типа дисков gp2
  # Для других типов дисков они могут быть иными — подробнее см. в документации на диски
  description = "Enter the volume size for VM disks (32 by default, in GiB, must be multiple of 32)"
  default     = 32                              # Размер диска в ГБ 
}

variable "allowed_ip" {
  description = "Allowed IP for external access"
  type        = list(string)
  default     = ["ххх.ххх.ххх.ххх/32"]             # IP-адреса для внешнего доступа (CIDR)
}
