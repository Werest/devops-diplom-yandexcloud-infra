# Создаём VPC, подсети в трёх зонах, группы безопасности,
# ВМ для мастер-ноды и воркер-нод (прерываемые для воркеров)

# Сеть
resource "yandex_vpc_network" "k8s_net" {
  name = var.vpc_name
}

# Подсети
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = var.availability_zones["a"]
  network_id     = yandex_vpc_network.k8s_net.id
  v4_cidr_blocks = [var.subnet_cidrs["a"]]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = var.availability_zones["b"]
  network_id     = yandex_vpc_network.k8s_net.id
  v4_cidr_blocks = [var.subnet_cidrs["b"]]
}

# Группа безопасности для доступа к API и ssh
resource "yandex_vpc_security_group" "k8s_sg" {
  name       = "k8s-security-group"
  network_id = yandex_vpc_network.k8s_net.id

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidrs
    content {
      protocol       = "TCP"
      port           = 22
      v4_cidr_blocks = [ingress.value]
      description    = "SSH"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_api_cidrs
    content {
      protocol       = "TCP"
      port           = 6443
      v4_cidr_blocks = [ingress.value]
      description    = "Kubernetes API"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_api_cidrs
    content {
      protocol       = "TCP"
      port           = 31000
      v4_cidr_blocks = [ingress.value]
      description    = "Grafana"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_api_cidrs
    content {
      protocol       = "TCP"
      port           = 32000
      v4_cidr_blocks = [ingress.value]
      description    = "WebApp"
    }
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound"
  }
}

locals {
  # Приоритет: файл (если существует) -> переменная
  ssh_public_key = try(file(var.ssh_public_key_path), var.ssh_public_key)
}

# Мастер-нода (непрерываемая, для стабильности)
resource "yandex_compute_instance" "master" {
  name        = "k8s-master"
  platform_id = "standard-v2"
  zone        = var.availability_zones["a"]

  resources {
    cores  = var.master_cores
    memory = var.master_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.boot_disk_size
      type     = var.boot_disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_a.id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }
}

# Воркер-ноды (прерываемые)
resource "yandex_compute_instance" "worker" {
  count = 2
  name  = "k8s-worker-${count.index}"
  zone  = count.index == 0 ? var.availability_zones["a"] : var.availability_zones["b"]

  resources {
    cores  = var.worker_cores
    memory = var.worker_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.boot_disk_size
      type     = var.boot_disk_type
    }
  }

  network_interface {
    subnet_id          = count.index == 0 ? yandex_vpc_subnet.subnet_a.id : yandex_vpc_subnet.subnet_b.id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.worker_preemptible
  }
}

resource "local_file" "kubespray_inventory" {
  content = templatefile("${path.module}/hosts.tftpl", {
    master  = yandex_compute_instance.master
    workers = yandex_compute_instance.worker
  })
  filename = "./inventory.ini"
}