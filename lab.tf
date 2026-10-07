locals {
  vms = {
    k8s-cp     = { id = 501, ip = "10.10.10.61", ram = 4096, disk = 20 }
    k8s-w1     = { id = 502, ip = "10.10.10.62", ram = 4096, disk = 20 }
    k8s-w2     = { id = 503, ip = "10.10.10.63", ram = 4096, disk = 20 }
    jenkins    = { id = 504, ip = "10.10.10.64", ram = 4096, disk = 30 }
    monitoring = { id = 505, ip = "10.10.10.65", ram = 3072, disk = 30 }
  }
}

resource "proxmox_virtual_environment_vm" "lab" {
  for_each  = local.vms
  name      = each.key
  node_name = "homelab-node3-Z600"
  vm_id     = each.value.id
  pool_id   = "lab"
  tags      = ["lab", "terraform"]

  clone {
    vm_id        = 9000
    full         = true
    datastore_id = "lab-ssd"
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.ram
  }

  disk {
    datastore_id = "lab-ssd"
    interface    = "scsi0"
    size         = each.value.disk
  }

  agent {
    enabled = false
  }

  initialization {
    datastore_id = "lab-ssd"
    user_account {
      username = "shigonn"
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.10.10.1"
      }
    }
    dns {
      servers = ["10.10.10.1", "1.1.1.1"]
    }
  }
}
