resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_image" "app_image" {
  name = "mi_app"
  build {
    context = "${path.module}/Práctica1RedesAvanzadas/app"
  }
}

resource "docker_volume" "static_files" {
  name = "shared_static_files"
}

resource "docker_container" "app_container" {
  count  = var.instance_count
  name   = "app_container_${count.index}"
  image  = docker_image.app_image.name
  networks_advanced {
    name = docker_network.app_network.name
  }

  ports {
    internal = var.app_port
   # external = var.app_port
  }
  
  # Monta el volumen de archivos estáticos
  volumes {
    host_path      = "${abspath(path.module)}/Práctica1RedesAvanzadas/app/static"
    container_path = "/app/static"  # Ruta en el contenedor donde se accede a los archivos
  }

  env = [
    "DATABASE_URL=${var.database_url}",
    "CACHE_URL=${var.cache_url}"
  ]

  depends_on = [docker_container.fluentbit]
}


resource "docker_volume" "db_volume" {
  name = "db_data_volume"
}

resource "docker_container" "db_container" {
  name  = "db"
  image = "postgres:13"
  networks_advanced {
    name = docker_network.app_network.name
  }
  volumes {
    volume_name    = docker_volume.db_volume.name
    container_path = "/var/lib/postgresql/data"
  }
  ports {
    internal = var.db_port
    external = var.db_port
  }

  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}"
  ]

  depends_on = [docker_container.fluentbit]
}


resource "docker_image" "redis_image" {
  name = "redis:latest"
}

resource "docker_container" "cache_container" {
  name  = "cache"
  image = docker_image.redis_image.name
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = var.cache_port
    external = var.cache_port
  }

  depends_on = [docker_container.fluentbit]
}

resource "docker_image" "nginx_image" {
  name = "nginx:latest"
}

resource "docker_container" "nginx_lb" {
  name  = "nginx_lb"
  image = docker_image.nginx_image.name
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = var.lb_port
    external = var.lb_port
  }

  volumes {
    # Mapea el archivo de configuración nginx.conf
    host_path      = "${abspath(path.module)}/nginx.conf"
    container_path = "/etc/nginx/nginx.conf"
  }

  env = [
    for i in range(0, var.instance_count) : 
      "APP_SERVER_${i+1}=${"app_container_${i}:5000"}"
  ]

  depends_on = [docker_container.fluentbit]
  restart = "always"
}


resource "docker_container" "prometheus" {
  image = "prom/prometheus"
  name  = "prometheus"

  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "${abspath(path.module)}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}


resource "docker_container" "grafana" {
  image = "grafana/grafana:latest"
  name  = "grafana"

  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 3000
    external = 3000
  }

  volumes {
    host_path      = "${abspath(path.module)}/path/to/host/grafana/data"
    container_path = "/var/lib/grafana"
  }

  env = [
    "GF_SECURITY_ADMIN_USER=${var.gf_user}",
    "GF_SECURITY_ADMIN_PASSWORD=${var.gf_password}"
  ]

  # Asegúrate de que Grafana depende de Loki y Prometheus
  depends_on = [docker_container.loki, docker_container.prometheus]
}



resource "docker_container" "fluentbit" {
  image = "grafana/fluent-bit-plugin-loki"
  name  = "fluentbit"

  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 24224
    external = 24224
  }

  volumes {
    host_path      = "${abspath(path.module)}/fluent-bit.conf"
    container_path = "/fluent-bit/etc/fluent-bit.conf"
  }
  restart = "always"
}

resource "docker_container" "loki" {
  image = "grafana/loki:latest"
  name  = "loki"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 3100
    external = 3100
  }
}