variable "instance_count" {
  type    = number
}

variable "app_port" {
  type    = number
  default = 5000
}

variable "database_url" {
  type = string
}

variable "cache_url" {
  type    = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_user" {
  type = string
}


variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
  default = "app_db_prod"
}

variable "cache_port" {
  description = "Puerto para acceder al servicio de caché"
  type        = number
  default     = 6379
}

variable "lb_port" {
  description = "Puerto en el que el balanceador de carga escucha en el host"
  type        = number
  default     = 8080  # Puedes elegir el puerto que prefieras, como 80 o 8080
}

variable "gf_user" {
  type = string
}

variable "gf_password" {
  type = string
}