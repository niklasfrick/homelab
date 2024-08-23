####################################################
# Terraform Configuration: 
# Create VM on Proxmox from a full clone
####################################################

# VM Name: srv-01.home.balzers.xyz
# Description: Untrusted Server VLAN Server 1
# IP Address: 10.96.20.11/24
# VLAN: 962 (Untrusted Server VLAN)

resource "proxmox_vm_qemu" "srv_01" {
    
    # VM General Settings
    target_node = "pve-01"
    vmid = "201"
    name = "srv-01.home.balzers.xyz"
    desc = "Untrusted Server VLAN Server 1"
    pool = "pbs-backup"
    tags = "pbs-backup, untrusted-server-vlan"
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
    memory = 8192

    scsihw = "virtio-scsi-single"

    disk {
      slot            = 0
      size            = "60G"
      type            = "virtio"
      storage         = "local-lvm"
    }

    # VM Network Settings
    network {
        bridge = "vmbr0"
        model  = "virtio"
        tag = 962
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    ipconfig0 = "ip=10.96.20.11/24,gw=10.96.20.1"
    nameserver = "10.96.20.1"
    searchdomain ="home.balzers.xyz"
    ciuser = var.ci_user
    cipassword = var.ci_password
    
    sshkeys = <<EOF
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIveS+0VyQkUC+y/FECgIGPxphMoO+2/Khoy7vR4LzDn Niklas-MBP
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINo56L/uj6myLZT+doLr6Be4n2r8zppgouLtV8gTECuh niklas@im.local.zazen.li
    EOF
}

resource "unifi_user" "srv_01" {
  mac  = proxmox_vm_qemu.srv_01.network[0].macaddr
  name = proxmox_vm_qemu.srv_01.name
  note = proxmox_vm_qemu.srv_01.desc
  # local_dns_record = proxmox_vm_qemu.srv_01.name

  fixed_ip   = proxmox_vm_qemu.srv_01.default_ipv4_address
  network_id = proxmox_vm_qemu.srv_01.network[0].tag
}

resource "ansible_host" "srv_01" {
  name = proxmox_vm_qemu.srv_01.name
  groups = ["rhel_hosts", "linux", "k3s-trusted"]
}