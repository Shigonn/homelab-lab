# homelab-lab

A DevOps training lab built entirely from code and rebuildable from scratch.
Terraform provisions the VMs on Proxmox VE; Ansible configures them.

## What it builds

| VM | Role |
|----|------|
| k8s-cp, k8s-w1, k8s-w2 | Kubernetes v1.35 cluster (kubeadm, containerd, Flannel) |
| monitoring | Prometheus + Grafana, node exporter on every VM |
| jenkins | Jenkins LTS on Java 21 |
| lab-control | Workstation running Terraform and Ansible |

## Stack

- **Terraform** (bpg/proxmox provider): VMs cloned from a Debian 13 cloud-init template
- **Ansible**: node prep, Kubernetes prerequisites, monitoring stack, Jenkins
- **Kubernetes** via kubeadm, 1 control plane and 2 workers
- **Prometheus / Grafana**: 15-day retention, Node Exporter Full dashboard
- **Jenkins**: installed from the official apt repository

## Layout

- `providers.tf`, `lab.tf`: Terraform definitions for the lab VMs
- `ansible/inventory.ini`: host groups
- `ansible/k8s-prep.yml`: swap off, kernel modules, sysctl, containerd, kubeadm packages
- `ansible/node-exporter.yml`, `monitoring.yml`, `grafana.yml`: observability
- `ansible/jenkins.yml`: Jenkins

## Rebuild

1. Provide Proxmox API credentials via environment variables (never committed).
2. `terraform apply -parallelism=2`
3. `ansible-playbook k8s-prep.yml`, then `kubeadm init` and join the workers.
4. `ansible-playbook node-exporter.yml monitoring.yml grafana.yml jenkins.yml`

## Notes and lessons

- Debian's containerd defaults to a CNI binary path that does not exist;
  `bin_dir` must point at `/opt/cni/bin` or CoreDNS hangs in ContainerCreating.
- Minimal Debian 13 cloud images have no `gpg`, so apt repositories are added
  with Ansible's `deb822_repository` module instead of `apt_repository`.
- Secrets, state files and tfvars are excluded via `.gitignore`.

## Roadmap

kubectl from the control host, a real app with Ingress, RBAC and NetworkPolicy
(Calico/Cilium), Helm, Jenkins pipelines, GitLab CI, an AWS free-tier project
with a budget alarm.
