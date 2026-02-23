locals {
  # 固定キー（インデックス）で作る：plan時点で確定できる
  # route_table_ids は unknown の可能性があるので key に含めない
  rt_cidr_pairs = flatten([
    for rt_idx in range(length(var.route_table_ids)) : [
      for cidr_idx in range(length(var.onprem_cidr_blocks)) : {
        key    = "${rt_idx}-${cidr_idx}"
        rt_idx = rt_idx
        cidr   = var.onprem_cidr_blocks[cidr_idx]
      }
    ]
  ])
}

resource "aws_vpn_gateway" "this" {
  amazon_side_asn = var.amazon_side_asn
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vgw"
  })
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = var.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this.id
}

resource "time_sleep" "wait_vgw_attachment" {
  depends_on      = [aws_vpn_gateway_attachment.this]
  create_duration = "30s"
}

resource "aws_customer_gateway" "this" {
  bgp_asn    = var.customer_gateway_bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cgw"
  })
}

resource "aws_vpn_connection" "this" {
  vpn_gateway_id      = aws_vpn_gateway.this.id
  customer_gateway_id = aws_customer_gateway.this.id
  type                = "ipsec.1"

  static_routes_only = var.static_routes_only

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpn"
  })

  depends_on = [aws_vpn_gateway_attachment.this]
}

# Static routes (only when static_routes_only = true)
resource "aws_vpn_connection_route" "onprem" {
  for_each = var.static_routes_only ? toset(var.onprem_cidr_blocks) : toset([])

  vpn_connection_id      = aws_vpn_connection.this.id
  destination_cidr_block = each.value
}

# Add VPC route table routes toward VGW (private route tables recommended)
resource "aws_route" "to_onprem" {
  for_each = {
    for p in local.rt_cidr_pairs : p.key => p
  }

  route_table_id         = var.route_table_ids[each.value.rt_idx]
  destination_cidr_block = each.value.cidr
  gateway_id             = aws_vpn_gateway.this.id

  depends_on = [time_sleep.wait_vgw_attachment]
}