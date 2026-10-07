terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

provider "proxmox" {}

resource "proxmox_virtual_environment_vm" "test" {
  name      = "lab-test"
  node_name = "homelab-node3-Z600"
  vm_id     = 599
  pool_id   = "lab"

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
    dedicated = 2048
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
        address = "10.10.10.69/24"
        gateway = "10.10.10.1"
      }
    }
    dns {
      servers = ["10.10.10.1", "1.1.1.1"]
    }
  }
}
