resource "yandex_lb_target_group" "lb-balancer-group" {
  name       = "lb-balancer-group"
  depends_on = [yandex_compute_instance.master]

  dynamic "target" {
    for_each = yandex_compute_instance.worker
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

# Сетевой балансировщик с двумя слушателями
resource "yandex_lb_network_load_balancer" "app-lb" {
  name = "app-load-balancer"

  # Слушатель 1: внешний порт 3100 -> целевой порт 31000
  listener {
    name        = "grafana-3100"
    port        = 3100
    target_port = 31000
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  # Слушатель 2: внешний порт 80 -> целевой порт 32000
  listener {
    name        = "web-app-80"
    port        = 80
    target_port = 32000
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  # Привязываем целевую группу с health check
  attached_target_group {
    target_group_id = yandex_lb_target_group.lb-balancer-group.id

    healthcheck {
      name                = "tcp-health-check"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      tcp_options {
        port = 33000
      }
    }
  }
}