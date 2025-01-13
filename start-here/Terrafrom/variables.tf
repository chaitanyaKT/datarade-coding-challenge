variable "net" {
  type = map(string)
  default = {
    cidr = "172.31.0.0/16"
  }
}