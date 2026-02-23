output "resolver_sg_id" {
  value       = aws_security_group.resolver.id
  description = "Security Group ID for resolver endpoints"
}

output "outbound_endpoint_id" {
  value       = try(aws_route53_resolver_endpoint.outbound[0].id, null)
  description = "Route53 Resolver Outbound Endpoint ID"
}

output "inbound_endpoint_id" {
  value       = try(aws_route53_resolver_endpoint.inbound[0].id, null)
  description = "Route53 Resolver Inbound Endpoint ID"
}

# Inbound Endpoint の IP（オンプレDNSが forward する先）
output "inbound_ip_addresses" {
  value = try(
    [for a in aws_route53_resolver_endpoint.inbound[0].ip_address : a.ip],
    []
  )
  description = "Inbound endpoint IP addresses (AWS side). Configure on-prem DNS forwarders to these."
}