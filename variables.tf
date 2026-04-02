###cloud vars
variable "yc_cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  default = "b1g5lq99m43jv5mpei89"
}

variable "yc_folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  default = "b1g88k8r3li6sb89l14s"
}

variable "yc_default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "image_id" {
  type = string
  default = "fd8jjccig145ofgp5b9u"
}

variable "boot_disk_type" {
  type = string
  default = "network-hdd"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key"
  sensitive   = false
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

# Ресурсы ВМ
variable "master_cores" {
  type    = number
  default = 2
}
variable "master_memory" {
  type    = number
  default = 4
}
variable "worker_cores" {
  type    = number
  default = 2
}
variable "worker_memory" {
  type    = number
  default = 4
}
variable "boot_disk_size" {
  type    = number
  default = 20
}

# Сеть
variable "vpc_name" {
  type    = string
  default = "k8s-network"
}
variable "subnet_cidrs" {
  type = map(string)
  default = {
    a = "10.1.0.0/24"
    b = "10.2.0.0/24"
  }
}
variable "availability_zones" {
  type = map(string)
  default = {
    a = "ru-central1-a"
    b = "ru-central1-b"
  }
}

# Security group
variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "allowed_api_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# Preemptible для worker
variable "worker_preemptible" {
  type    = bool
  default = true
}