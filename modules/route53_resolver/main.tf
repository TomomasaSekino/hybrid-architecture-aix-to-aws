resource "aws_security_group" "resolver" {
  name        = "${var.name_prefix}-resolver-sg"
  description = "Security group for Route 53 Resolver endpoints"
  vpc_id      = var.vpc_id

  # Inbound endpoint: On-Prem -> AWS inbound endpoint (TCP/UDP 53)
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.onprem_cidr_blocks
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.onprem_cidr_blocks
  }

  # Outbound endpoint: AWS -> On-Prem DNS (allow all egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-resolver-sg"
  })
}

# -------------------------
# Outbound Endpoint (AWS -> On-Prem)
# -------------------------
resource "aws_route53_resolver_endpoint" "outbound" {
  count              = var.enable_outbound ? 1 : 0
  name               = "${var.name_prefix}-resolver-outbound"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.resolver.id]

  # subnet_ids は通常2つ以上（AZ冗長）
  dynamic "ip_address" {
    for_each = var.subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }

  tags = var.tags
}

resource "aws_route53_resolver_rule" "forward" {
  count                = var.enable_outbound ? 1 : 0
  domain_name          = var.domain_name
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound[0].id

  dynamic "target_ip" {
    for_each = var.onprem_dns_ips
    content {
      ip = target_ip.value
    }
  }

  tags = var.tags
}

resource "aws_route53_resolver_rule_association" "vpc" {
  count            = var.enable_outbound ? 1 : 0
  resolver_rule_id = aws_route53_resolver_rule.forward[0].id
  vpc_id           = var.vpc_id
}

# -------------------------
# Inbound Endpoint (On-Prem -> AWS)
# -------------------------
resource "aws_route53_resolver_endpoint" "inbound" {
  count              = var.enable_inbound ? 1 : 0
  name               = "${var.name_prefix}-resolver-inbound"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.resolver.id]

  # 冗長化のためサブネット複数指定
  dynamic "ip_address" {
    for_each = var.subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }

  tags = var.tags
}