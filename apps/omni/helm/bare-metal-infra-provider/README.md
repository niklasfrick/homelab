# Bare Metal Infrastructure Provider Helm Chart

This Helm chart deploys the [Sidero Labs Bare Metal Infrastructure Provider](https://docs.siderolabs.com/omni/omni-cluster-setup/setting-up-the-bare-metal-infrastructure-provider) for Omni.

## Overview

The Bare Metal Infrastructure Provider enables Omni to manage bare-metal machines with BMC (IPMI/Redfish) capabilities. It provides:

- **PXE Boot Server**: Boots bare-metal machines over the network
- **TFTP Server**: Serves iPXE binaries (listens on port 69)
- **DHCP Proxy**: Responds to PXE boot requests
- **API Server**: Provides HTTP/GRPC API for Omni integration (default port 50042)

## Prerequisites

1. An Omni instance (SaaS or self-hosted) with admin access
2. Bare-metal machines with:
   - BMC support (IPMI or Redfish)
   - Network boot (PXE) capability
   - Network access to this provider
3. A Kubernetes cluster in the same network as the bare-metal machines
4. Service account key from Omni (stored via ExternalSecret)

## Installation

### 1. Create Omni Bare Metal Infra Provider

Create a bare-metal infra provider in Omni (this will create a service account and display the service account key):

```bash
# Using omnictl
omnictl infraprovider create bare-metal
```

The output will include the service account key. Save this key securely for use in the next steps.
```

Or via the Omni Web UI: _Settings → Infra Providers → New Infra Provider Setup_

Store the service account key in your secrets manager.

### 2. Configure Values

Update your values file (e.g., `omni-local-bare-metal-infra-provider-helm-values.yaml`):

```yaml
omni:
  endpoint: "https://omni.your-domain.com"
  
# IMPORTANT: Set this to the IP where bare-metal machines can reach the provider
apiAdvertiseAddress: "172.16.0.42"

# Optional: Pin the pod to a specific node with a known IP
deployment:
  nodeSelector:
    kubernetes.io/hostname: your-node-name
```

### 3. Install the Chart

```bash
helm install bare-metal-infra-provider ./apps/omni/helm/bare-metal-infra-provider \
  --namespace omni-bmip \
  --create-namespace \
  -f ./apps/omni/settings/omni-local/omni-local-bare-metal-infra-provider-helm-values.yaml
```

## Configuration

### Key Values

| Parameter                           | Description                                                  | Default                                  |
| ----------------------------------- | ------------------------------------------------------------ | ---------------------------------------- |
| `omni.endpoint`                     | Omni instance URL                                            | `https://my-instance.omni.siderolabs.io` |
| `omni.serviceAccountKeySecret.name` | Secret name containing service account key                   | `service-account-key`                    |
| `omni.serviceAccountKeySecret.key`  | Key in secret                                                | `serviceAccountKey`                      |
| `apiAdvertiseAddress`               | IP address where bare-metal machines can reach this provider | `""` (required)                          |
| `providerId`                        | Provider ID (must match Omni service account)                | `bare-metal`                             |
| `service.apiPort`                   | API/GRPC port                                                | `50042`                                  |
| `deployment.nodeSelector`           | Pin pod to specific node(s)                                  | `{}`                                     |

### Network Requirements

- The provider runs with `hostNetwork: true` to bind to privileged ports
- Port 69 (UDP): TFTP server - must be accessible by bare-metal machines
- Port 50042 (TCP): API/GRPC - used by Omni to communicate with provider
- The `apiAdvertiseAddress` must be reachable by bare-metal machines

### Important Notes

1. **Host Network**: The pod runs with `hostNetwork: true` because it needs to bind to port 69 (TFTP)
2. **Node Selection**: Consider using `nodeSelector` to pin the pod to a node with a stable, known IP address
3. **Single Replica**: Only one replica is supported due to the stateful nature of the provider
4. **Service Account**: The provider ID must match the service account name in Omni (default: `bare-metal`)

## Usage

After deployment:

1. Verify the provider is running:
   ```bash
   kubectl logs -n omni deployment/bare-metal-infra-provider
   ```

2. Configure bare-metal machines to boot via PXE on next boot

3. Power cycle the machines - they should boot into Talos Agent Mode

4. Accept machines in Omni via Web UI or omnictl:
   ```bash
   omnictl machine accept <machine-id>
   ```

5. Add accepted machines to clusters as normal

## Troubleshooting

### Provider not starting
- Check that the service account key is correct
- Verify the Omni endpoint is accessible from the cluster

### Machines not PXE booting
- Ensure machines are configured for network boot
- Check that port 69 (UDP) is accessible from bare-metal machines
- Verify DHCP is working on the network

### Machines boot but don't show in Omni
- Check that machines can reach the Omni endpoint (SideroLink)
- Verify firewall rules allow outbound connections

## References

- [Setting Up the Bare-Metal Infrastructure Provider](https://docs.siderolabs.com/omni/omni-cluster-setup/setting-up-the-bare-metal-infrastructure-provider)
- [Omni Documentation](https://docs.siderolabs.com/omni/)
- [Provider GitHub Repository](https://github.com/siderolabs/omni-infra-provider-bare-metal)

