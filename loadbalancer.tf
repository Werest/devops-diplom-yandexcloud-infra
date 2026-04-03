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

# LB Grafana
resource "yandex_lb_network_load_balancer" "lb-grafana" {
  name = "lb-grafana"

  listener {
    name        = "grafana-listener"
    port        = 80
    target_port = 31000
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lb-balancer-group.id

    healthcheck {
      name                = "healthcheck-grafana"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      tcp_options {
        port = 31000
      }
    }
  }
}

# LB WEBAPP
resource "yandex_lb_network_load_balancer" "lb-webapp" {
  name = "lb-webapp"

  listener {
    name        = "webapp-listener"
    port        = 80
    target_port = 32000
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lb-balancer-group.id

    healthcheck {
      name                = "healthcheck-webapp"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      tcp_options {
        port = 32000
      }
    }
  }
}

output "lb_grafana_ip" {
  value = yandex_lb_network_load_balancer.lb-grafana.listener.*.external_address_spec[0].*.address
}

output "lb_webapp_ip" {
  value = yandex_lb_network_load_balancer.lb-webapp.listener.*.external_address_spec[0].*.address
}