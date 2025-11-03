0. Create Cluster via Omni + Apply config
1. Label Nodes
1.1 BGP to all nodes
   ```bash
   kubectl label nodes --all bgp=65020
   ```
1.2 Label worker nodes manually:
```bash
kubectl label node t3s-zendo-w<1-3> node-role.kubernetes.io/worker=worker
```
1. Install Gateway API CRDs
2. Install Cilim with helm values
3. Install Cilium-Config with helm values
4. Install External Secrets
5. Create Secret for ESO
6. Install External Secrets with helm values
7. Install ArgoCD
8. Install ArgoCD Bootstrap Helm Chart