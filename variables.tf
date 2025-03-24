variable "instance_name" {
  type = string
}

variable "vm_ports" {
  type = list(number)
}

variable "database_port" {
  type = number
}

variable "cache_port" {
  type = number
}

variable "efs_port" {
  type = number
}

variable "logs_bucket_arn" {
  type        = string
  description = ""
}

variable "allow_lb_cidr_block" {
  type = list(string)
  default = ["0.0.0.0/0"]
}
