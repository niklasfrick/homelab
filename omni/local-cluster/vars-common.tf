variable "network_gateway_ip" {
  description = "The IP address of the network gateway"
  type        = string
}

variable "dns_domain" {
  description = "The DNS domain to append to hostnames for local DNS records"
  type        = string
}
