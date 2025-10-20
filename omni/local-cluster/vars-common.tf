variable "infisical_client_id" {
  description = "The client ID for the Infisical API"
  type        = string
  sensitive   = true
}

variable "unifi_hostname" {
  description = "The API URL for the Unifi controller"
  type        = string
}

variable "network_gateway_ip" {
  description = "The IP address of the network gateway"
  type        = string
}

variable "infisical_client_secret" {
  description = "The client secret for the Infisical API"
  type        = string
  sensitive   = true
}

variable "dns_domain" {
  description = "The DNS domain to append to hostnames for local DNS records"
  type        = string
}
