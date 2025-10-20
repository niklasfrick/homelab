resource "unifi_user" "this" {
  for_each         = merge(var.node_data.controlplanes, var.node_data.workers)
  mac              = each.value.mac_address
  name             = each.value.hostname
  note             = each.value.description
  fixed_ip         = each.key
  local_dns_record = "${each.value.hostname}.${var.dns_domain}"
}

resource "unifi_dns_record" "cluster-endpoint-vip" {
  name        = "${var.cluster_name}.${var.dns_domain}"
  enabled     = true
  port        = 0
  record_type = "A"
  value       = var.cluster_endpoint_vip
}

data "talos_image_factory_urls" "this" {
  talos_version = "v${var.talos_version}"
  schematic_id  = "80469ef645425bc7cb27830a7143999e422fd7b206c9d9726c47de47800e956d"
  platform      = "metal"
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_name}.${var.dns_domain}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = "v${var.talos_version}"
  kubernetes_version = "v${var.kubernetes_version}"
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_name}.${var.dns_domain}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = "v${var.talos_version}"
  kubernetes_version = "v${var.kubernetes_version}"
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = concat([for k, v in var.node_data.controlplanes : k])
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    unifi_user.this,
    unifi_dns_record.cluster-endpoint-vip
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.node_data.controlplanes
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/talos-config/control-plane.yaml.tmpl", {
      hostname             = each.value.hostname
      ip_address           = each.key
      gateway_ip           = var.network_gateway_ip
      cluster_endpoint_vip = var.cluster_endpoint_vip
      cluster_domain       = "${var.cluster_name}.${var.dns_domain}"
    }),
    templatefile("${path.module}/talos-config/default.yaml.tmpl", {
      installer_image = data.talos_image_factory_urls.this.urls.installer
      install_disk    = each.value.install_disk
      gateway_ip      = var.network_gateway_ip
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    unifi_user.this
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.node_data.workers
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/talos-config/worker-node.yaml.tmpl", {
      hostname             = each.value.hostname
      ip_address           = each.key
      gateway_ip           = var.network_gateway_ip
      cluster_endpoint_vip = var.cluster_endpoint_vip
      cluster_domain       = "${var.cluster_name}.${var.dns_domain}"
    }),
    templatefile("${path.module}/talos-config/default.yaml.tmpl", {
      installer_image = data.talos_image_factory_urls.this.urls.installer
      install_disk    = each.value.install_disk
      gateway_ip      = var.network_gateway_ip
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.cluster_endpoint_vip
}
