# Local Cluster Bootstrap

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

## Next Steps

After bootstrapping the cluster:

1. Install Cilium for container networking (see cluster-specific documentation)
2. Deploy any necessary CNI configurations
3. Verify all nodes are in "Ready" state
4. Deploy workloads

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
