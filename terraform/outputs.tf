output "vpc-west" {
  value = module.vpc.first.vpc_id
}

output "vpc-east" {
  value = module.vpc.second.vpc_id
}

output "vpc_peering_connection" {
  value = aws_vpc_peering_connection.pc.id
}