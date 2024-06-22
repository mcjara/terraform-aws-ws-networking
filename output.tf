output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.public-subnets[*].id
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
  value = length(aws_security_group.database) > 0 ? aws_security_group.database[0].id : ""
}

output "cache_sec_group" {
  value = length(aws_security_group.cache) > 0 ? aws_security_group.cache[0].id : ""
}

output "efs_sec_group" {
  value = aws_security_group.efs.id
}
