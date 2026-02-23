resource "aws_route53_zone" "private" {
  name = var.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  comment = "Private Hosted Zone for hybrid DNS demonstration"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-phz"
  })
}

# サンプルレコード（オンプレから引ける想定）
resource "aws_route53_record" "app_record" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "app.${var.zone_name}"
  type    = "A"
  ttl     = 300
  records = ["10.0.10.100"]
}