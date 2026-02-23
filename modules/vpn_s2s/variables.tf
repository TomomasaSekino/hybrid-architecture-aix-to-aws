variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to attach VGW"
}

variable "customer_gateway_ip" {
  type        = string
  description = "On-prem VPN device public IP (dummy allowed; recommend RFC5737 e.g., 203.0.113.10)"
}

variable "customer_gateway_bgp_asn" {
  type        = number
  description = "BGP ASN for customer gateway (required by AWS even if static routes are used)"
  default     = 65010
}

variable "onprem_cidr_blocks" {
  type        = list(string)
  description = "On-premise CIDR blocks reachable via VPN"
}

variable "route_table_ids" {
  type        = list(string)
  description = "Route table IDs (typically private) to add routes toward on-prem networks"
}

variable "static_routes_only" {
  type        = bool
  description = "If true, VPN uses static routes (simpler for prototype). If false, BGP is expected."
  default     = true
}

variable "amazon_side_asn" {
  type        = number
  description = "Amazon side ASN for VGW (only for VGW-based VPN). Optional."
  default     = 64512
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}