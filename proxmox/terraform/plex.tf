####################################################
# Terraform Configuration: 
# Create VM on Proxmox from a full clone
####################################################

# VM Name: plex.local.zazen.li
# Description: Plex Media Server (Untrusted Server VLAN)
# IP Address: 10.96.20.10/24
# VLAN: 962 (Untrusted Server VLAN)

resource "proxmox_vm_qemu" "plex" {
    
    # VM General Settings
    target_node = "pve"
    vmid = "200"
    name = "plex.local.zazen.li"
    desc = "Plex Media Server (Untrusted Server VLAN)"
    pool = "pbs-backup"
    tags = "pbs-backup"
    qemu_os = "l26"
    bios = "ovmf"

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
    memory = 4096

    scsihw = "virtio-scsi-single"

    # VM Network Settings
    network {
        bridge = "vmbr0"
        model  = "virtio"
        tag = 962
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    ipconfig0 = "ip=10.96.20.10/24,gw=10.96.20.1"
    nameserver = "10.96.20.1"
    searchdomain ="local.zazen.li"
    ciuser = var.ci_user
    cipassword = var.ci_password
    
    sshkeys = <<EOF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIveS+0VyQkUC+y/FECgIGPxphMoO+2/Khoy7vR4LzDn Niklas-MBP
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINo56L/uj6myLZT+doLr6Be4n2r8zppgouLtV8gTECuh niklas@im.local.zazen.li
    EOF
}

resource "unifi_user" "plex" {
  mac  = proxmox_vm_qemu.plex.network[0].macaddr
  name = proxmox_vm_qemu.plex.name
  note = proxmox_vm_qemu.plex.desc
  local_dns_record = proxmox_vm_qemu.plex.name

  fixed_ip   = proxmox_vm_qemu.plex.default_ipv4_address
  network_id = proxmox_vm_qemu.plex.network[0].tag
}

resource "ansible_host" "plex" {
  name = proxmox_vm_qemu.plex.name
  groups = ["rhel_hosts", "linux"]
}