variable "instance_name" {
  type = string
}

variable "application_ports" {
  type = list(number)
}

variable "database_port" {
  type = number
}

variable "cache_port" {
  type = number
}