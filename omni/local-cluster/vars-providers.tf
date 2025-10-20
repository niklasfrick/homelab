variable "infisical_client_id" {
  description = "The client ID for the Infisical API"
  type        = string
  sensitive   = true
}

variable "infisical_client_secret" {
  description = "The client secret for the Infisical API"
  type        = string
  sensitive   = true
}

variable "unifi_hostname" {
  description = "The API URL for the Unifi controller"
  type        = string
}
