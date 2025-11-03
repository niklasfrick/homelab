# MinIO Bucket Lifecycle Management

This directory contains lifecycle policies for managing object retention in MinIO S3 buckets.

## Overview

Lifecycle policies automatically delete objects after a set time period, helping manage storage costs and comply with data retention policies.

**Important:** Lifecycle policies do NOT work if versioning is suspended on the bucket. For lifecycle policies to work, the bucket should either have no versioning at all, or versioning should be enabled.

## Files

- `30d-retention-policy.json` - A 31-day retention policy with automatic deletion of old objects and cleanup of expired versions

## Applying a Lifecycle Policy

### Prerequisites

- MinIO Client (`mc`) installed and configured
- An alias configured for your MinIO instance (e.g., `minio`)
- Target bucket created

### Steps

1. **Create or modify a lifecycle configuration**
   
   The policy file defines rules for automatic object deletion. See `30d-retention-policy.json` for an example.

2. **Apply the lifecycle configuration to your bucket**

   Using MinIO Client:
   ```bash
   mc ilm rule import <alias_name>/<bucket_name> < 30d-retention-policy.json
   ```
   
   Example:
   ```bash
   mc ilm rule import minio/loki-logs < 30d-retention-policy.json
   ```

3. **Verify the lifecycle rules are applied**

   ```bash
   mc ilm rule ls <alias_name>/<bucket_name>
   ```

4. **Remove lifecycle rules (if needed)**

   Remove a specific rule:
   ```bash
   mc ilm rule rm --id "expiry" <alias_name>/<bucket_name>
   ```
   
   Remove all rules:
   ```bash
   mc ilm rule rm --all --force <alias_name>/<bucket_name>
   ```

## Policy Configuration Explained

The `30d-retention-policy.json` contains two rules:

### Rule 1: Expiry

| Option                                                    | Description                                                                                                                                    |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `Expiration: Days: 31`                                    | 31 days after an object was created, it is either permanently deleted (no versioning), or a delete marker is added (versioning enabled)        |
| `NoncurrentVersionExpiration: NoncurrentDays: 31`         | 31 days after an object became a "noncurrent version" (replaced by a newer version), it is permanently deleted — unless object lock is applied |
| `AbortIncompleteMultipartUpload: DaysAfterInitiation: 10` | 10 days after a multipart upload was aborted, the "leftover" parts are automatically deleted                                                   |

### Rule 2: Delete Marker Cleanup

| Option                            | Description                                                                                                                                                |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ExpiredObjectDeleteMarker: true` | If a delete marker is the only remaining version of an object and all noncurrent versions have been permanently deleted, the delete marker is also deleted |

## Alternative: Using MinIO Client Direct Commands

You can also set lifecycle rules directly without a JSON file:

```bash
# Set expiration rule
mc ilm rule add --expiry-days 31 <alias_name>/<bucket_name>

# Set noncurrent version expiration
mc ilm rule add --noncurrentversion-expiration-days 31 <alias_name>/<bucket_name>
```

## References

- [Hetzner Object Storage Lifecycle Management](https://docs.hetzner.com/storage/object-storage/howto-protect-objects/manage-lifecycle/)
- [MinIO ILM Documentation](https://min.io/docs/minio/linux/administration/object-management/object-lifecycle-management.html)

