0. Create Cluster via Omni + Apply config
1. Label worker nodes manually:
```bash
kubectl label node t3s-zendo-w<1-3> node-role.kubernetes.io/worker=worker
```
2. Install Gateway API CRDs
3. Install Cilim with helm values
4. Install Cilium-Config with helm values
5. Install External Secrets
6. Create Secret for ESO
7. Install External Secrets with helm values
8. Install ArgoCD
9. Install ArgoCD Bootstrap Helm Chart