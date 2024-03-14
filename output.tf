output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "private-subnets" {
  value = aws_subnet.private-subnets[*].id
}

output "alb-sec-group" {
  value = aws_security_group.alb.id
}

output "ec2-sec-group" {
  value = aws_security_group.ec2.id
}

output "rds-sec-group" {
  value = aws_security_group.rds.id
}

output "ec-sec-group" {
  value = aws_security_group.cache.id
}