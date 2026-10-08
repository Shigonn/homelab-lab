# homelab-lab

A DevOps training lab built entirely from code and rebuildable from scratch.
Terraform provisions the VMs on Proxmox VE; Ansible configures them; Helm
deploys cluster services; Jenkins checks every push.

## What it builds

| VM | Role |
|----|------|
| k8s-cp, k8s-w1, k8s-w2 | Kubernetes v1.35 cluster (kubeadm, containerd, Calico) |
| monitoring | Prometheus + Grafana, node exporter on every VM |
| jenkins | Jenkins LTS on Java 21, CI pipeline for this repo |
| lab-control | Workstation running Terraform, Ansible, kubectl and Helm |

Inside the cluster: MetalLB (layer 2, pool 10.10.10.66-70) gives bare-metal
LoadBalancer IPs, Traefik is the ingress controller, and a demo app
(Deployment + Service + Ingress) is served through it.

## Stack

- **Terraform** (bpg/proxmox provider): VMs cloned from a Debian 13 cloud-init template
- **Ansible**: node prep, Kubernetes prerequisites, monitoring, Jenkins, workstation tools
- **Kubernetes** via kubeadm, 1 control plane and 2 workers
- **Helm**: MetalLB and Traefik
- **Prometheus / Grafana**: 15-day retention, Node Exporter Full dashboard
- **Jenkins**: Pipeline from SCM; yamllint and ansible-playbook syntax checks

## Layout

- `providers.tf`, `lab.tf`: Terraform definitions for the lab VMs
- `ansible/inventory.ini`: host groups
- `ansible/k8s-prep.yml`: swap off, kernel modules, sysctl, containerd, kubeadm packages
- `ansible/node-exporter.yml`, `monitoring.yml`, `grafana.yml`: observability
- `ansible/jenkins.yml`, `jenkins-tools.yml`: Jenkins and its build tools
- `ansible/kubectl.yml`, `helm.yml`: workstation tooling
- `k8s/`: MetalLB address pool, Traefik Helm values, demo app manifests
- `Jenkinsfile`: CI pipeline

## Rebuild

1. Provide Proxmox API credentials via environment variables (never committed).
2. `terraform apply -parallelism=2`
3. `ansible-playbook k8s-prep.yml`, then `kubeadm init` and join the workers.
4. `ansible-playbook node-exporter.yml monitoring.yml grafana.yml jenkins.yml jenkins-tools.yml kubectl.yml helm.yml`
5. Copy the admin kubeconfig to lab-control (kept out of git).
6. Install MetalLB with Helm, then `kubectl apply -f k8s/metallb-pool.yaml`.
7. Install Traefik with Helm using `k8s/traefik-values.yaml`.
   (do this right after kubeadm init, before the workers join: from `k8s/calico/`, download the pinned v3.31.5 manifests with
   `curl -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.31.5/manifests/operator-crds.yaml`
   and the same URL ending in `tigera-operator.yaml`, then `kubectl create -f` both, then
   `kubectl create -f custom-resources.yaml`.)
8. `kubectl apply -f k8s/whoami.yaml`

## Notes and lessons

- Debian's containerd defaults to a CNI binary path that does not exist;
  `bin_dir` must point at `/opt/cni/bin` or CoreDNS hangs in ContainerCreating.
- Minimal Debian 13 cloud images have no `gpg`, so apt repositories are added
  with Ansible's `deb822_repository` module instead of `apt_repository`.
- The community ingress-nginx controller was retired in March 2026, so the
  lab uses Traefik; Gateway API is the planned next step.
- Jenkins defaults to the `master` branch; this repo uses `main`.
- CI was proven by deliberately pushing broken YAML, watching the build fail,
  then reverting and watching it pass.
- Secrets, state files, tfvars and kubeconfigs are excluded from the repo.

- CNI is Calico v3.31.5 (Tigera operator), pinned deliberately: newer releases
  default to native v3 CRDs, which on Kubernetes 1.35 need an extra API server
  feature gate. The v3.31 install is two manifests (`operator-crds.yaml`, then
  `tigera-operator.yaml`) applied with `kubectl create`, then
  `k8s/calico/custom-resources.yaml` with the pod CIDR set to 10.244.0.0/16.
- Replacing Flannel in place: delete its namespace and RBAC, install Calico,
  then `ansible/cni-cleanup.yml` removes Flannel's CNI config and reboots nodes
  workers-first, control plane last.
- NetworkPolicy is proven: default-deny in `demo`, then allow only the Traefik
  namespace; direct access from other namespaces times out.
## Roadmap

RBAC and namespaces, NetworkPolicy (swap Flannel for Calico/Cilium), Helm
chart authoring, Gateway API, Jenkins Configuration as Code, GitLab CI,
an AWS free-tier project with a budget alarm.
