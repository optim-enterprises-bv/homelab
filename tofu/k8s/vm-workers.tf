resource "proxmox_virtual_environment_vm" "workers" {
  provider  = proxmox.abel

  for_each = var.node_data.workers

  node_name = each.value.host_node

  name        = each.key
  description = "Talos Kubernetes Worker"
  tags        = ["k8s", "worker"]
  on_boot     = true
  vm_id       = each.value.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd = true
    # file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_id      = proxmox_virtual_environment_file.talos_nocloud_image[each.value.host_node].id
    file_format  = "raw"
    size         = 20
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    datastore_id      = "local-zfs"
#    meta_data_file_id = proxmox_virtual_environment_file.worker-config[each.key].id
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "192.168.1.1"
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }

#  hostpci {
#    # Passthrough iGPU
#    device = "hostpci0"
#    #id     = "0000:00:02"
#    mapping = "iGPU"
#    pcie    = true
#    rombar  = true
#    xvga    = false
#  }
}
