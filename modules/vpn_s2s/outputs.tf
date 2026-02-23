output "vpn_gateway_id" {
  value       = aws_vpn_gateway.this.id
  description = "VGW ID"
}

output "customer_gateway_id" {
  value       = aws_customer_gateway.this.id
  description = "Customer Gateway ID"
}

output "vpn_connection_id" {
  value       = aws_vpn_connection.this.id
  description = "VPN Connection ID"
}

output "vpn_connection_tunnel1_address" {
  value       = aws_vpn_connection.this.tunnel1_address
  description = "Tunnel 1 outside IP (AWS side)"
}

output "vpn_connection_tunnel2_address" {
  value       = aws_vpn_connection.this.tunnel2_address
  description = "Tunnel 2 outside IP (AWS side)"
}