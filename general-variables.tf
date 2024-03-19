variable "VPC_CIDR_BLOCK" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "VPC_PRIVATE_SUBNET_COUNT" {
  type        = number
  description = "Number of private subnets to create."
  default     = 2
}

variable "VPC_PUBLIC_SUBNETS_CIDR_BLOCK" {
  type        = list(string)
  description = "CIDR Block for Public Subnets in VPC"
  default     = ["10.0.112.0/20"]
}

variable "VPC_PRIVATE_SUBNETS_CIDR_BLOCK" {
  type        = list(string)
  description = "CIDR Block for Private Subnets in VPC"
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}