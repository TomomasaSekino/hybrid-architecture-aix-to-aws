output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpn_gateway_id" {
  value       = module.vpn.vpn_gateway_id
  description = "Virtual Private Gateway ID"
}

output "vpn_connection_id" {
  value       = module.vpn.vpn_connection_id
  description = "VPN Connection ID"
}

output "vpn_tunnel1_address" {
  value       = module.vpn.vpn_connection_tunnel1_address
  description = "VPN Tunnel 1 AWS-side address"
}

output "vpn_tunnel2_address" {
  value       = module.vpn.vpn_connection_tunnel2_address
  description = "VPN Tunnel 2 AWS-side address"
}

output "onprem_cidr_blocks" {
  value       = var.onprem_cidr_blocks
  description = "On-premise network CIDRs"
}

output "resolver_inbound_ip_addresses" {
  value       = module.resolver.inbound_ip_addresses
  description = "Route53 Resolver inbound endpoint IPs (configure on-prem DNS forwarders to these)"
}

output "private_zone_name" {
  value = module.private_hosted_zone.zone_name
}

output "private_zone_id" {
  value = module.private_hosted_zone.zone_id
}