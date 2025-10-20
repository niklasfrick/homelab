variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint_vip" {
  description = "The IP address of the cluster endpoint"
  type        = string
}

variable "talos_version" {
  description = "Talos Image Version"
  type        = string
}

variable "kubernetes_version" {
  description = "Talos Image Version"
  type        = string
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      mac_address  = string
      install_disk = string
      hostname     = optional(string)
      description  = optional(string)
    }))
    workers = map(object({
      mac_address  = string
      install_disk = string
      hostname     = optional(string)
      description  = optional(string)
    }))
  })
}
