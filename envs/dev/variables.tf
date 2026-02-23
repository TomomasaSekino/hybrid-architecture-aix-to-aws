variable "onprem_cidr_blocks" {
  type = list(string)

  default = [
    "172.16.0.0/16",
    "172.24.0.0/16"
  ]
}