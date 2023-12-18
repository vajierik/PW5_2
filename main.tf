terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "vajierik-bucket"
    region     = "ru-central1-a"
    key        = "sfstate/lemp-lamp.tfstate"
    access_key = "YCAJE4HX9KGVI_d_QGTwoIuRT"
    secret_key = "YCNxnGFcVQ1CSO4-pvoFo-X9gYpM2i1_WSsu8p7u"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token     = "y0_AgAAAAAH33B6AATuwQAAAAD0A7mP6OZQo1auSE6H3UXp0uHXF0pqdrY"
  cloud_id  = "b1gqkcvoua07qmolears"
  folder_id = "b1g35gfqsn2ee0jmmuvd"
}


resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}


module "ya_instance_1" {
  source                = "./modules/instance"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet1.id
  vpc_subnet_zone       = yandex_vpc_subnet.subnet1.zone
}

module "ya_instance_2" {
  source                = "./modules/instance"
  instance_family_image = "lamp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet2.id
  vpc_subnet_zone       = yandex_vpc_subnet.subnet2.zone
}

resource "yandex_lb_target_group" "lemp-lamp" {
  name = "lemp-lamp"

  target {
    subnet_id = yandex_vpc_subnet.subnet1.id
    address   = module.ya_instance_1.internal_ip_address_vm
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet2.id
    address   = module.ya_instance_2.internal_ip_address_vm
  }

}

resource "yandex_lb_network_load_balancer" "lb-lemp-lamp" {
  name = "lb-lemp-lamp"

  listener {
    name = "listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lemp-lamp.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

