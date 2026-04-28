# Omni OCI and Gateway API Migration Runbook

This runbook covers the migration from the vendored Omni chart to
`oci://ghcr.io/siderolabs/charts/omni` and from Ingress to Gateway API.

## What Went Wrong

The first cutover reached the Omni UI, but clusters were missing or login failed
because several chart assumptions changed at once:

1. The vendored chart passed `--account-id="{{ uuid }}"`, including literal
   quotes. Existing Omni resources were stored under that quoted account ID in
   etcd. The upstream chart reads `config.account.id` without those quotes, so
   Omni initially looked in an empty account namespace.
2. Existing machines still used the legacy join-token flow. The upstream chart
   defaults to stricter token handling, so `joinTokensMode: legacyAllowed` is
   required during this migration.
3. The upstream chart moved persistent data to `/data`. The old chart stored
   etcd under `etcd/` and SQLite under `sqlite/omni-sqlite.db` on `omni-pvc`.
   The upstream chart expects `/data/etcd/` and
   `/data/secondary-storage/sqlite.db`.
4. Running the new upstream storage layout on the NFS-backed `nfs-csi-retain`
   PVC caused SQLite lock contention and startup failures. Omni's embedded etcd
   and SQLite paths are hot local database paths, so the new `omni` PVC should
   use `local-path`.

The working migration keeps the old `omni-pvc` as a read-only source, creates a
new `local-path` PVC named `omni`, and lets an init container copy legacy data
into the new upstream paths before Omni starts.

## Current Compatibility Settings

Keep these values during the migration:

- `config.services.siderolink.joinTokensMode: legacyAllowed`
- `args: ["--account-id=\"8b965a24-0dce-4481-840f-b5548ea1c139\""]`
- `persistence.storageClassName: local-path`
- `initContainers.migrate-legacy-storage` mounted with:
  - new chart PVC `data` at `/data`
  - old PVC `omni-pvc` at `/legacy`

The init container is idempotent:

- It copies `/legacy/etcd/.` to `/data/etcd/` only when
  `/data/etcd/member` does not exist.
- It copies SQLite only when `/data/secondary-storage/sqlite.db` does not exist.
- It accepts either legacy SQLite source:
  - `/legacy/secondary-storage/sqlite.db`
  - `/legacy/sqlite/omni-sqlite.db`

## Pre-Flight Inventory

Before syncing the new `omni` Argo CD Application, capture the current state:

```sh
kubectl -n argocd get application omni -o yaml
kubectl -n omni get deploy,svc,ingress,httproute,grpcroute,pvc,secret
kubectl -n omni get deploy omni -o jsonpath='{.spec.template.spec.containers[0].args}'
kubectl -n omni get pvc omni-pvc omni -o yaml
kubectl -n omni get secret etcd-gpg-asc-key -o yaml
```

Confirm the existing installation is healthy before the maintenance window:

- `https://omni.apps-omni.949x.net` loads and Auth0 login works.
- Existing machines and clusters are visible in Omni.
- Generated kubeconfigs can reach `https://kubernetes.omni.apps-omni.949x.net`.
- SideroLink machine API traffic reaches `https://siderolink.omni.apps-omni.949x.net`.
- WireGuard is reachable at `10.96.10.101:30180`.
- Workload proxy URLs under `*.proxy.apps-omni.949x.net` work if in use.

## Step-By-Step Migration

1. Scale Omni down so no writes happen during the cutover:

   ```sh
   kubectl -n omni scale deploy/omni --replicas=0
   ```

2. Snapshot or otherwise back up the old `omni-pvc`. Do not delete it; the init
   container reads from it.

3. If a previous failed upstream attempt created an `omni` PVC on NFS, delete
   that new PVC after verifying the old `omni-pvc` backup exists:

   ```sh
   kubectl -n omni delete pvc omni
   ```

   Kubernetes will not mutate an existing PVC's `storageClassName`, so this is
   required for the new `local-path` PVC to be created.

4. Sync the updated Omni Application:

   ```sh
   argocd app sync omni
   ```

   The chart should create a new `omni` PVC with `storageClassName: local-path`.

5. Watch the init container:

   ```sh
   kubectl -n omni get pods -w
   kubectl -n omni logs deploy/omni -c migrate-legacy-storage
   ```

   Expected messages include:

   - `Copying legacy etcd data into /data/etcd`
   - `Copying legacy SQLite database from ... into /data/secondary-storage/sqlite.db`

   If SQLite says it skipped, check whether the target DB already exists or
   whether the old PVC has the source at `sqlite/omni-sqlite.db`.

6. Start or let Omni start after the init container completes. Watch logs for
   storage and account-id issues:

   ```sh
   kubectl -n omni logs deploy/omni -f
   ```

7. Validate Omni data:

   ```sh
   omnictl get clusters
   omnictl get machines
   ```

   The UI should show the migrated cluster and machines.

8. Validate route attachment:

   ```sh
   kubectl -n omni get httproute omni-ui omni-k8s-proxy omni-workload-proxy -o wide
   kubectl -n omni get grpcroute omni-siderolink -o wide
   kubectl -n kube-system get gateway internal-gateway -o yaml
   ```

   The Kubernetes proxy and SideroLink routes use the
   `https-omni-subdomain` listener because `*.apps-omni.949x.net` does not cover
   two-label names such as `kubernetes.omni.apps-omni.949x.net`. The workload
   proxy route uses `https-workload-proxy` for the same wildcard-matching reason.

9. After the new deployment is validated, remove the temporary migration
   `initContainers` and `extraVolumes` entries. Keep `local-path`,
   `joinTokensMode: legacyAllowed`, and the quoted `--account-id` until a
   deliberate follow-up migration removes those compatibility settings.

10. Sync with prune only after storage, UI, login, and routes are validated:

    ```sh
    argocd app sync omni --prune
    ```

## Rollback

If the OCI chart cannot read existing state or Gateway API cannot carry traffic:

1. Stop the new Omni pod to avoid additional writes to the new `omni` PVC.
2. Revert the `omni` Application source to `apps/omni/helm/omni`.
3. Restore the previous v1-style values.
4. Keep the old `omni-pvc` as the rollback source; restore its snapshot only if
   it was modified during manual work.
5. Re-enable the previous Ingress resources through the old values.
