output "alb" {
  value = aws_security_group.alb.id
}

output "service" {
  value = aws_security_group.service.id 
}

output "subnet_public_0" {
  value = aws_subnet.dsc_public_subnets[0].id
}

output "subnet_public_1" {
  value = aws_subnet.dsc_public_subnets[1].id
}
