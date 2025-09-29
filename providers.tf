terraform {
  required_providers {
    aws = {
      source  = "hc-registry.website.k2.cloud/c2devel/rockitcloud"
      version = "25.3.0"
    }
  }
}

provider "aws" {
  # Используются для работы с определенным сервисом
  # endpoints {
      # ec2 = "https://ec2.ru-msk.k2.cloud"
      # paas = "https://paas.ru-msk.k2.cloud"
      # eks = "https://eks.ru-msk.k2.cloud"
      # s3 = https://s3.ru-msk.k2.cloud

  # }

  insecure = false
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}