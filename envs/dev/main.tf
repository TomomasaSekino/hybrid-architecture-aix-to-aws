module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = local.name_prefix

  vpc_cidr = "10.0.0.0/16"
  az_count = 2

  tags = local.common_tags
}

module "vpn" {
  source      = "../../modules/vpn_s2s"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  # ダミーでOK（RFC5737のテスト用アドレス推奨）
  customer_gateway_ip      = "203.0.113.10"
  customer_gateway_bgp_asn = 65010

  onprem_cidr_blocks = var.onprem_cidr_blocks

  # Private RTにオンプレ向けルートを入れる
  route_table_ids = module.vpc.private_route_table_ids

  static_routes_only = true

  tags = local.common_tags
}