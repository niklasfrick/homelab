# Homelab Infrastructure

GitOps-managed Kubernetes homelab built on **Talos Linux**, **Sidero Omni**, and **ArgoCD**.

<p align="center">
  <img src="https://docs.siderolabs.com/images/favicon.svg" alt="Talos Linux" height="60"/>
  <img src="https://mintlify.s3.us-west-1.amazonaws.com/siderolabs-fe86397c/images/omni.svg" alt="Sidero Omni" height="60"/>
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/argo/icon/color/argo-icon-color.png" alt="ArgoCD" height="60"/>
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/cilium/icon/color/cilium_icon-color.png" alt="Cilium" height="60"/>
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/prometheus/icon/color/prometheus-icon-color.png" alt="Prometheus" height="60"/>
  &nbsp;&nbsp;
  <img src="https://avatars.githubusercontent.com/u/7195757?s=80" alt="Grafana" height="60"/>
</p>

---

## Components

### Platform

| Component                                   | Description                     |                                                                                                                           |
| ------------------------------------------- | ------------------------------- | :-----------------------------------------------------------------------------------------------------------------------: |
| [Talos Linux](https://www.talos.dev/)       | Secure, immutable Kubernetes OS |                          <img src="https://docs.siderolabs.com/images/favicon.svg" height="25"/>                          |
| [Sidero Omni](https://omni.siderolabs.com/) | Kubernetes cluster management   |         <img src="https://mintlify.s3.us-west-1.amazonaws.com/siderolabs-fe86397c/images/omni.svg" height="25"/>          |
| [ArgoCD](https://argo-cd.readthedocs.io/)   | GitOps continuous delivery      | <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/argo/icon/color/argo-icon-color.png" height="25"/> |

### Networking

| Component                                                       | Description                     |                                                                                                                                           |
| --------------------------------------------------------------- | ------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------: |
| [Cilium](https://cilium.io/)                                    | eBPF CNI with BGP & Gateway API |       <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/cilium/icon/color/cilium_icon-color.png" height="25"/>       |
| [cert-manager](https://cert-manager.io/)                        | TLS certificate automation      | <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/cert-manager/icon/color/cert-manager-icon-color.png" height="25"/> |
| [External DNS](https://github.com/kubernetes-sigs/external-dns) | DNS record management           |                 <img src="https://kubernetes-sigs.github.io/external-dns/latest/docs/img/external-dns.png" height="25"/>                  |
| [Tailscale](https://tailscale.com/)                             | VPN mesh networking             |                <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/tailscale-light.webp" height="25"/>                 |

### Storage

| Component                                                                   | Description              |                                                                                                                           |
| --------------------------------------------------------------------------- | ------------------------ | :-----------------------------------------------------------------------------------------------------------------------: |
| [Rook Ceph](https://rook.io/)                                               | Distributed storage      | <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/rook/icon/color/rook-icon-color.png" height="25"/> |
| [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) | Node-local storage       |                       <img src="https://static.thenounproject.com/png/585904-200.png" height="25"/>                       |
| [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs)          | NFS storage provisioning |                                                                                                                           |

### Observability

| Component                             | Description                |                                                                                                                                       |
| ------------------------------------- | -------------------------- | :-----------------------------------------------------------------------------------------------------------------------------------: |
| [Prometheus](https://prometheus.io/)  | Metrics & alerting         | <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/prometheus/icon/color/prometheus-icon-color.png" height="25"/> |
| [Grafana](https://grafana.com/)       | Visualization & dashboards |                             <img src="https://avatars.githubusercontent.com/u/7195757?s=40" height="25"/>                             |
| [Loki](https://grafana.com/oss/loki/) | Log aggregation            |                  <img src="https://raw.githubusercontent.com/grafana/loki/main/docs/sources/logo.png" height="25"/>                   |
| [Thanos](https://thanos.io/)          | Long-term metrics storage  |     <img src="https://raw.githubusercontent.com/cncf/artwork/main/projects/thanos/icon/color/thanos-icon-color.png" height="25"/>     |

### Security

| Component                                        | Description                |                                                                                                                             |
| ------------------------------------------------ | -------------------------- | :-------------------------------------------------------------------------------------------------------------------------: |
| [External Secrets](https://external-secrets.io/) | Secret sync from Infisical | <img src="https://raw.githubusercontent.com/external-secrets/external-secrets/main/assets/eso-logo-large.png" height="25"/> |
| [Velero](https://velero.io/)                     | Backup & disaster recovery |                     <img src="https://grafana.com/media/solutions/Velero/velero-icon.jpg" height="25"/>                     |

### Data & Compute

| Component                                                                     | Description          |                                                                                                                                         |
| ----------------------------------------------------------------------------- | -------------------- | :-------------------------------------------------------------------------------------------------------------------------------------: |
| [CloudNative PG](https://cloudnative-pg.io/)                                  | PostgreSQL operator  |                                <img src="https://cloudnative-pg.io/images/hero_image.png" height="25"/>                                 |
| [ClickHouse](https://clickhouse.com/)                                         | Analytics database   |                       <img src="https://upload.wikimedia.org/wikipedia/commons/0/0e/Clickhouse.png" height="25"/>                       |
| [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/) | NVIDIA GPU support   |    <img src="https://www.citypng.com/public/uploads/preview/hd-nvidia-eye-logo-icon-png-701751694965655t2lbe7yugk.png" height="25"/>    |
| [vLLM](https://vllm.ai/)                                                      | LLM inference server | <img src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/dark/vllm-color.png" height="25"/> |

---

## Clusters

| Cluster        | Type                 | Purpose                 | Nodes            |
| -------------- | -------------------- | ----------------------- | ---------------- |
| **omni-local** | Talos (Single Node)  | Omni management cluster | 1 CP             |
| **zendo**      | Talos (Omni-managed) | Production workloads    | 3 CP + 4 Workers |
| **spark**      | RKE2                 | Edge/experimental       | Variable         |

---

## Repository Structure

```
homelab/
├── apps/                      # Application configs & Helm values
│   ├── argocd/                # ArgoCD + bootstrap chart
│   ├── argocd-apps/           # App-of-apps definitions
│   ├── cilium/                # CNI + BGP/Gateway config
│   ├── omni/                  # Self-hosted Omni + BMIP
│   └── .../                   # Other applications
└── clusters/                  # Cluster-specific configs
    ├── omni-local/            # Talos config (talhelper)
    └── zendo/                 # Omni-managed cluster
```

---

## Omni Single-Node Cluster

### Day 0 — Preparation

1. **Install tools**: `talosctl`, `kubectl`, `talhelper`, `helm`, `infisical`
2. **Store secrets** in Infisical at `/omni/omni-local-cluster`
3. **Configure** `clusters/omni-local/talos-config/talconfig.yaml`
4. **Generate configs**: `just generate`

### Day 1 — Bootstrap

1. **Boot node** with Talos media
2. **Apply config**: `talosctl apply-config --insecure --nodes <ip> --file <config>`
3. **Bootstrap cluster**: `talosctl bootstrap -n <ip>`
4. **Get kubeconfig**: `talosctl kubeconfig`
5. **Install CNI**: Gateway API CRDs → Cilium → Cilium Config
6. **Install External Secrets**: Helm chart → Infisical auth secret → ClusterSecretStore
7. **Install ArgoCD**: Helm chart → `argocd-init` bootstrap chart

### Day 2 — GitOps

ArgoCD manages everything via app-of-apps pattern:

```
argocd-init → argocd-apps → [all applications]
```

**To add/update apps**: Modify files in `apps/`, commit, push — ArgoCD auto-syncs.

---

## Omni-Managed Bare Metal Cluster

### Day 0 — Preparation

**Option A**: Download Talos image from Omni UI  
**Option B**: Configure Bare Metal Infrastructure Provider for PXE boot

### Day 1 — Build Cluster

1. **Boot machines** with Omni media — machines auto-register via SideroLink
2. **Create cluster** in Omni UI — assign control planes and workers
3. **Apply config** via Omni (automatic with patches)
4. **Bootstrap components**: Label nodes → Install Cilium → External Secrets → ArgoCD

### Day 2 — GitOps

Same as omni-local. ArgoCD syncs cluster-specific values from `apps/*/settings/zendo/`.

---

## Quick Reference

| Cluster    | Pod CIDR      | Service CIDR  | VIP          |
| ---------- | ------------- | ------------- | ------------ |
| omni-local | 10.11.0.0/16  | 10.12.0.0/16  | 10.96.10.100 |
| zendo      | 10.111.0.0/16 | 10.112.0.0/12 | 10.96.10.150 |

**Detailed bootstrap instructions**: See [`clusters/omni-local/README.md`](clusters/omni-local/README.md)

---

## Resources

- [Talos Linux](https://www.talos.dev/) · [Sidero Omni](https://omni.siderolabs.com/) · [ArgoCD](https://argo-cd.readthedocs.io/) · [Cilium](https://docs.cilium.io/)
