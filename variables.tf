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
  default = "ru-msk"                             # Регион cкрыт в terraform.tfvars
}

variable "public_key" {
  description = "pub_key"
  sensitive = true                               # Скрыт в terraform.tfvars SSH публичный ключ
}

variable "pubkey_name" {
  description = "pubkey_name"
  default = "terra"                              # Имя SSH-ключа в облаке
}

# variable "bucket_name" {
#   description = "Enter the bucket name"        
# }

variable "az" {
  description = "Enter availability zone (ru-msk-comp1p by default)"
  default     = "ru-msk-comp1p"                 # Зона доступности
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
  description = "Enter the template ID to create a VM from (cmi-AC76609F [CentOS 8.2] by default)"
  default     = "cmi-C45746AF"                  # ID образа K2 Cloud
}

variable "vm_instance_type" {
  description = "Enter the instance type for a VM (m5.2small by default)"
  default     = "m5.large"                      # Тип инстанса
}

variable "vm_volume_type" {
  description = "Enter the volume type for VM disks (gp2 by default)"
  default     = "st2"                           # Тип диска 
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
  default     = ["xxx.xxx.xxx.xxx/32"]             # IP-адреса для внешнего доступа (CIDR)
}
