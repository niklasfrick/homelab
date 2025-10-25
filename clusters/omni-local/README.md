# Omni Local Cluster Bootstrap

This directory contains the configuration and instructions for bootstrapping a local Talos Kubernetes cluster.

## Prerequisites

Ensure the following tools are installed:

- [talosctl](https://www.talos.dev/latest/introduction/getting-started/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [talhelper](https://github.com/budimanjojo/talhelper) (for configuration generation)

## Configuration Generation

The Talos cluster configuration is managed in the `talos-config/` directory. Before bootstrapping, you must generate the configuration files.

**See [talos-config/README.md](talos-config/README.md) for detailed instructions on generating the configuration.**

## Bootstrapping the Cluster

Once the configuration has been generated in the `talos-config/clusterconfig/` directory, follow these steps to bootstrap your cluster:

### 1. Apply Configuration to Nodes

Apply the generated configuration to each node. Start with the master node(s):

```bash
talosctl apply-config --insecure --nodes <master-node-ip> --file talos-config/clusterconfig/master-node-1.yaml
```

Repeat this process for additional nodes (control planes and workers), using the appropriate configuration file for each node.

> **Note**: The `--insecure` flag is used for initial configuration application when the node doesn't have a valid certificate yet.

### 2. Wait for Node Reboot

After applying the configuration, wait a few minutes for the nodes to reboot and come back online.

### 3. Configure Talosctl

Copy the generated `talosconfig` to your Talos configuration directory:

```bash
cp talos-config/clusterconfig/talosconfig $HOME/.talos/configs/<desired-name>-talosconfig
```

Activate this configuration. You can either:

- Use [talswitcher](https://github.com/mirceanton/talswitcher) to switch between configurations
- Or manually set it as your default:
  ```bash
  export TALOSCONFIG=$HOME/.talos/configs/<desired-name>-talosconfig
  ```

### 4. Bootstrap Talos

Initialize the Talos cluster by bootstrapping the first control plane node:

```bash
talosctl bootstrap -n <master-node-ip>
```

> **Important**: Only run bootstrap on one control plane node. It initializes etcd and can only be done once per cluster.

### 5. Generate Kubeconfig

Optionally, you can set the Talos cluster endpoint using the DNS name for your control plane, which enables access via the API server load balancer or DNS.

```bash
talosctl config endpoint <your-control-plane-dns-or-lb>
```

Replace `<your-control-plane-dns-or-lb>` with the DNS name or load balancer address of your Talos control plane (e.g., `talos.example.com`).

> **Tip:** This is especially useful if your control plane has a stable DNS entry to a VIP or load balancer in front of it.


Generate the Kubernetes configuration file and save it to your home directory:

```bash
talosctl -n <master-node-ip> kubeconfig $HOME/.kube/config
```

If you want to merge with an existing kubeconfig or save to a different location, specify the path accordingly.

### 6. Verify Node Status

Check the status of your nodes:

```bash
kubectl get nodes
```

> **Note**: Since this cluster uses Cilium for container networking, nodes will not be in "Ready" state immediately. They will transition to "Ready" after Cilium is installed and configured.

### 7. Installing and Configuing Cilium CNI

1. Install the custom Gateway API CRDs Helm chart first, which is located at `charts/gateway-api-crds`:
   
   ```bash
   helm upgrade --install gateway-api-crds apps/gateway-api-crds/helm \
     --namespace kube-system
   ```

   This step ensures the Gateway API CRDs are available before deploying other charts that depend on them.

2. Install Cilium for container networking using Helm and the values provided in `apps/cilium/global-cilium-helm-values.yaml`. For example:

   ```bash
   helm repo add cilium https://helm.cilium.io/
   helm repo update
   helm upgrade --install cilium cilium/cilium \
     --namespace kube-system \
     -f apps/cilium/settings/global-cilium-helm-values.yaml
   ```

   (See cluster-specific documentation for customizations.)

2. Label Nodes for BGP Advertisement
3. 
   ```bash
   kubectl label nodes --all bgp=65020
   ```

4. Deploy the Cilium config Helm chart using the provided values file in `apps/cilium-config/omni-local/`:

   ```bash
   helm install cilium-config apps/cilium-config/helm \
     --namespace kube-system \
     -f apps/cilium-config/settings/omni-local/omni-local-cilium-config-helm-values.yaml
   ```
5. Verify all nodes are in "Ready" state

### 8. Install External Secrets Operator & Cluster Secret Store

Install External Secrets Operator without specific Configuration. We will need this in order to get the CRDs. We want them to be managed via the helm chart so we first need to install it without our clustersecretstore as its an extraObject in the helm values we will use later. This would lead to an error as the CRDs are not installed yet.

```bash
helm repo add external-secrets https://charts.external-secrets.io/
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --wait
```

Then create the Infisical authentication secret for our clustersecretstore. We get the necessary secrets from infisical too. Inception complete... ;-)

```bash
kubectl create secret generic infisical-auth-credentials \
    --namespace=external-secrets \
    --from-literal=clientId=$(infisical secrets get --token=$INFISICAL_TOKEN --projectId=$INFISICAL_PROJECT_ID --env=prod --path=/infisical GLOBAL_INFISICAL_CLIENT_ID --plain) \
    --from-literal=clientSecret=$(infisical secrets get --token=$INFISICAL_TOKEN --projectId=$INFISICAL_PROJECT_ID --env=prod --path=/infisical GLOBAL_INFISICAL_CLIENT_SECRET --plain)
```

Finally upgrade the External Secrets Operator Helm Chart with the values (We deploy the clustersecretstore as an extraObject)

```bash
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  -f apps/external-secrets/settings/global-external-secrets-helm-values.yaml \
  --wait
```

### 9. Initialize GitOps with Argo CD

The cluster uses [Argo CD](https://argo-cd.readthedocs.io/) for GitOps-based application management.

#### a. Install Argo CD

Deploy the official Argo CD Helm chart into the `argocd` namespace:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace
```

The helm chart should be installed without values. We will next install the ArgoCD Init helm chart and here we will deploy the app of apps pattern. Afterwards argocd will be self-managed and the helm values will be set from there on GitOps-style.

#### c. Install the Argo CD Bootstrap Helm Chart

Install the custom Argo CD bootstrap chart (`argocd-init`) to configure Argo CD, its credentials as external secrets, and repo accesses. The chart is located under `charts/argocd-init`:

```bash
helm upgrade --install argocd-init apps/argocd/helm/argocd-init \
  --namespace argocd \
  -f apps/argocd/settings/omni-local/omni-local-argocd-init-helm-values.yaml
```

#### d. (Optional) Accessing the Argo CD UI

After installation, you can access the Argo CD UI and log in. Refer to [the official Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/) for instructions on forwarding the service and obtaining the initial admin password.



## Troubleshooting

### Nodes Not Responding

If nodes don't respond after configuration application:
- Verify the IP addresses are correct
- Check network connectivity to the nodes
- Review node logs: `talosctl -n <node-ip> logs`

### Bootstrap Fails

If bootstrap fails:
- Ensure only one node is being bootstrapped
- Check etcd logs: `talosctl -n <node-ip> logs etcd`
- Verify the configuration was applied successfully

### Nodes Stuck in "NotReady"

This is expected before Cilium installation. Nodes require a CNI (Container Network Interface) plugin to become fully operational.

## Resources

- [Talos Documentation](https://www.talos.dev/)
- [Talos Bootstrap Guide](https://www.talos.dev/latest/introduction/getting-started/)
- [Cilium Documentation](https://docs.cilium.io/)
