packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.7"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "redhat_image" {
  type    = string
  default = "rhel-9.3-x86_64-dvd.iso"
}

variable "proxmox_iso_pool" {
  type    = string
  default = env("proxmox_iso_pool")
}

variable "proxmox_node" {
  type    = string
  default = env("proxmox_node")
}

variable "proxmox_api_token" {
  type      = string
  default   = env("proxmox_api_token")
  sensitive = true
}

variable "proxmox_storage_format" {
  type    = string
  default = env("proxmox_storage_format")
}

variable "proxmox_storage_pool" {
  type    = string
  default = env("proxmox_storage_pool")
}

variable "proxmox_storage_pool_type" {
  type    = string
  default = env("proxmox_storage_pool_type")
}

variable "proxmox_api_url" {
  type    = string
  default = env("proxmox_api_url")
}

variable "proxmox_api_username" {
  type      = string
  default   = env("proxmox_api_username")
  sensitive = true
}

variable "template_description" {
  type    = string
  default = "Red Hat 9.3 Server Template bare installation"
}

variable "template_name" {
  type    = string
  default = "rhel9-server-template"
}

variable "version" {
  type    = string
  default = ""
}

variable "rh_username" {
  type      = string
  default   = env("rh_username")
  sensitive = true
}

variable "rh_password" {
  type      = string
  default   = env("rh_password")
  sensitive = true
}

source "proxmox-iso" "autogenerated_1" {
  boot_command = ["<up><wait><tab><wait> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  boot_wait    = "10s"
  cores        = "1"
  cpu_type     = "host"
  machine      = "q35"
  disks {
    disk_size    = "20G"
    format       = "${var.proxmox_storage_format}"
    storage_pool = "${var.proxmox_storage_pool}"
    type         = "virtio"
  }
  http_directory           = "rhel9"
  insecure_skip_tls_verify = true
  iso_file                 = "${var.proxmox_iso_pool}/${var.redhat_image}"
  memory                   = "2048"
  qemu_agent               = true
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    vlan_tag = "961"
    firewall = false
  }
  node                    = "${var.proxmox_node}"
  os                      = "l26"
  proxmox_url             = "${var.proxmox_api_url}"
  username                = "${var.proxmox_api_username}"
  token                   = "${var.proxmox_api_token}"
  scsi_controller         = "virtio-scsi-pci"
  ssh_password            = "Packer"
  ssh_port                = 22
  ssh_timeout             = "30m"
  ssh_username            = "root"
  template_description    = "${var.template_description}"
  template_name           = "${var.template_name}"
  unmount_iso             = true
  cloud_init              = true
  cloud_init_storage_pool = "${var.proxmox_storage_pool}"
  vm_id                   = "900"
}

build {
  sources = ["source.proxmox-iso.autogenerated_1"]

  name = "rhel9-server-template"

  provisioner "shell" {
    inline = [
      "subscription-manager register --username ${var.rh_username} --password ${var.rh_password}",
      "subscription-manager attach --auto",
    ]
  }

  provisioner "shell" {
    inline = ["yum install -y cloud-init cloud-utils-growpart gdisk", "shred -u /etc/ssh/*_key /etc/ssh/*_key.pub", "rm -f /var/run/utmp", ">/var/log/lastlog", ">/var/log/wtmp", ">/var/log/btmp", "rm -rf /tmp/* /var/tmp/*", "unset HISTFILE; rm -rf /home/*/.*history /root/.*history", "rm -f /root/*ks", "passwd -d root", "passwd -l root", "rm -f /etc/ssh/ssh_config.d/allow-root-ssh.conf"]
  }

}