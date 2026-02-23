variable "name_prefix" { type = string }
variable "vpc_id" { type = string }

# Resolver endpoint を置くサブネット（通常はPrivate×2以上）
variable "subnet_ids" {
  type = list(string)
}

# On-prem DNS servers (FORWARD先)
variable "onprem_dns_ips" {
  type = list(string)
}

# Forwardするドメイン（例：kuromimishowkai.local）
variable "domain_name" {
  type = string
}

# オンプレ側CIDR（Inboundの許可元）
variable "onprem_cidr_blocks" {
  type = list(string)
  description = "On-premise CIDRs allowed to query inbound endpoint"
}

# Inbound/Outboundの有効化フラグ（将来切替しやすい）
variable "enable_outbound" {
  type    = bool
  default = true
}

variable "enable_inbound" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}