output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnets" {
  value = aws_subnet.private-subnets[*].id
}

output "lb_sec_group" {
  value = aws_security_group.lb.id
}

output "vm_sec_group" {
  value = aws_security_group.vm.id
}

output "database_sec_group" {
  value = aws_security_group.database.id
}

output "cache_sec_group" {
  value = aws_security_group.cache.id
}