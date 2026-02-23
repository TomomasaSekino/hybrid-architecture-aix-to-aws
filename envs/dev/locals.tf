locals {
  name_prefix = "hybrid-aix-aws-dev"

  common_tags = {
    Project     = "hybrid-architecture-aix-to-aws"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}