# Omni OCI and Gateway API Migration Runbook

This runbook supports the migration from the vendored Omni chart to
`oci://ghcr.io/siderolabs/charts/omni` and from Ingress to Gateway API.

## Pre-Flight Inventory

Run these before syncing the new `omni` Argo CD Application:

```sh
kubectl -n argocd get application omni -o yaml
kubectl -n omni get deploy,svc,ingress,httproute,grpcroute,pvc,secret
kubectl -n omni get deploy omni -o jsonpath='{.spec.template.spec.containers[0].args}'
kubectl -n omni get pvc omni-pvc -o yaml
kubectl -n omni get secret etcd-gpg-asc-key -o yaml
```

Confirm the current installation is healthy:

- `https://omni.apps-omni.949x.net` loads and Auth0 login works.
- Existing machines and clusters are visible in Omni.
- Generated kubeconfigs can reach `https://kubernetes.omni.apps-omni.949x.net`.
- SideroLink machine API traffic reaches `https://siderolink.omni.apps-omni.949x.net`.
- WireGuard is reachable at `10.96.10.101:30180`.
- Workload proxy URLs under `*.proxy.apps-omni.949x.net` work if in use.

## Persistence Cutover

The upstream v2 chart mounts persistent data at `/data`. The vendored chart
mounted the existing `omni-pvc` at `/_out`, with SQLite explicitly configured
under `/_out/sqlite/omni-sqlite.db`. This migration lets the upstream chart
create its own default PVC and uses the upstream default storage paths.

Because the storage class is NFS-backed, copy the old database files into the
new PVC through the file storage before allowing Omni to start.

Recommended order:

1. Scale or pause Omni during the maintenance window.
2. Snapshot or copy the old `omni-pvc`.
3. Sync far enough for the upstream chart to create the new PVC, expected to be
   named `omni`, while the `verify-existing-omni-data` initContainer blocks the
   Omni container from starting.
   Confirm both PVCs are present with `kubectl -n omni get pvc omni-pvc omni`.
4. Copy the old etcd database directory from `etcd/` on the old PVC into the
   new PVC at `etcd/`.
5. Copy the old SQLite database file from `sqlite/omni-sqlite.db` into the new
   PVC at `secondary-storage/sqlite.db`.
6. Restart or let the pod retry so the `verify-existing-omni-data` initContainer
   can pass.
7. Start Omni and watch for database decryption, storage, and account ID errors.

If Omni starts with missing data or storage errors, stop the new pod immediately
and restore the previous Argo CD Application source and values. Restore the old
PVC snapshot only if the old PVC was modified during the migration.

## Gateway API Validation

After the controlled sync, validate route attachment:

```sh
kubectl -n omni get httproute omni-ui omni-k8s-proxy omni-workload-proxy -o wide
kubectl -n omni get grpcroute omni-siderolink -o wide
kubectl -n kube-system get gateway internal-gateway -o yaml
```

All routes should report accepted parent refs and resolved backend refs. The
Kubernetes proxy and SideroLink routes use the `https-omni-subdomain` listener
because `*.apps-omni.949x.net` does not cover two-label names such as
`kubernetes.omni.apps-omni.949x.net`. The workload proxy route uses the separate
`https-workload-proxy` listener for the same wildcard-matching reason.

The `omni` Application is intentionally rendered without automated sync during
this migration. After the routes and storage have been validated, run:

```sh
argocd app sync omni --prune
```

This removes the legacy Ingress resources from the vendored chart. Re-enable
automated sync only after the OCI deployment has been validated.

## Rollback

If the OCI chart cannot read existing state or Gateway API cannot carry traffic:

1. Stop the new Omni pod to avoid additional writes to the new PVC.
2. Revert the `omni` Application source to `apps/omni/helm/omni`.
3. Restore the previous v1-style values.
4. Keep the old `omni-pvc` as the rollback source; restore its snapshot only if
   it was modified during manual copy work.
5. Re-enable the previous Ingress resources through the old values.
