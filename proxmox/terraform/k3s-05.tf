####################################################
# Terraform Configuration: 
# Create VM on Proxmox from a full clone
####################################################

# VM Name: k3s-05.home.balzers.xyz
# Description: Trusted Server VLAN k3s Server 5
# IP Address: 10.96.10.24/24
# VLAN: 961 (Trusted Server VLAN)

resource "proxmox_vm_qemu" "k3s_05" {
    
    # VM General Settings
    target_node = "pve-01"
    vmid = "106"
    name = "k3s-05.home.balzers.xyz"
    desc = "Trusted Server VLAN k3s Server 5"
    pool = "pbs-backup"
    tags = "pbs-backup"
    qemu_os = "l26"

    # VM Advanced General Settings
    onboot = true 

    # VM OS Settings
    clone = "rhel9-server-template"

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 6144

    scsihw = "virtio-scsi-single"

    disk {
      slot            = 0
      size            = "80G"
      type            = "virtio"
      storage         = "local-lvm"
    }

    # VM Network Settings
    network {
        bridge = "vmbr0"
        model  = "virtio"
        tag = 961
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    ipconfig0 = "ip=10.96.10.24/24,gw=10.96.10.1"
    nameserver = "10.96.10.1"
    searchdomain ="home.balzers.xyz"
    ciuser = var.ci_user
    cipassword = var.ci_password
    
    sshkeys = <<EOF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIveS+0VyQkUC+y/FECgIGPxphMoO+2/Khoy7vR4LzDn Niklas-MBP
    EOF
}

resource "unifi_user" "k3s_05_trusted" {
  mac  = proxmox_vm_qemu.k3s_05.network[0].macaddr
  name = proxmox_vm_qemu.k3s_05.name
  note = proxmox_vm_qemu.k3s_05.desc
  # local_dns_record = proxmox_vm_qemu.k3s_05.name

  fixed_ip   = proxmox_vm_qemu.k3s_05.default_ipv4_address
  network_id = proxmox_vm_qemu.k3s_05.network[0].tag
}

resource "ansible_host" "k3s_05" {
  name = proxmox_vm_qemu.k3s_05.name
  groups = ["rhel_hosts", "linux", "k3s-trusted"]
}