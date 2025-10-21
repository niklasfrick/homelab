# Talos Configuration with Infisical Secret Management

This directory contains the Talos cluster configuration managed with [talhelper](https://github.com/budimanjojo/talhelper) and secrets stored in [Infisical](https://infisical.com/).

## Prerequisites

Ensure the following tools are installed:

- [infisical CLI](https://infisical.com/docs/cli/overview)
- [talhelper](https://github.com/budimanjojo/talhelper)
- [talosctl](https://www.talos.dev/latest/introduction/getting-started/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [direnv](https://direnv.net/)

### Infisical Setup

Before proceeding, you need to:

1. **Set up Infisical backend**: Ensure you have access to an Infisical instance (cloud or self-hosted)
2. **Create a Machine Identity**: Follow the [Universal Auth documentation](https://infisical.com/docs/documentation/platform/identities/universal-auth) to:
   - Create a machine identity in your Infisical organization
   - Configure Universal Auth for the identity
   - Create a Client Secret and obtain the Client ID
   - Add the identity to your project with appropriate permissions

## Initial Setup

### 1. Generate and Store Talos Secrets

First, generate the necessary Talos secrets:

```bash
talhelper gensecret > talsecret.temp.yaml
```

This creates a temporary file with all the required secrets. Now:

1. Open `talsecret.yaml.bak` and copy each secret value
2. Store each secret in Infisical with the **same name** as referenced in `talsecret.yaml`
3. Make sure the secret names match exactly (e.g., `CLUSTERID`, `CLUSTERSECRET`, `BOOTSTRAPTOKEN`, etc.)

> ⚠️ **Important**: The templated `talsecret.yaml` file is already present in the repository. Never commit actual secret values!

### 2. Configure Environment Variables

Create a `.env` file in this directory with your Infisical credentials:

```bash
# .env
INFISICAL_CLIENT_ID=your-client-id-here
INFISICAL_CLIENT_SECRET=your-client-secret-here
INFISICAL_PROJECT_ID=your-project-id-here
INFISICAL_DOMAIN=https://app.infisical.com  # or your self-hosted domain
```
Allow direnv to export these environment variables:

```bash
direnv allow
```

## Usage

### Generate Talos Configuration

To generate the Talos configuration files with secrets injected from Infisical:

1. **Obtain an Infisical token**:

```bash
export INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id=$INFISICAL_CLIENT_ID \
  --client-secret=$INFISICAL_CLIENT_SECRET \
  --projectId=$INFISICAL_PROJECT_ID \
  --domain=$INFISICAL_DOMAIN \
  --silent \
  --plain)
```

2. **Generate configuration with secrets injection**:

```bash
infisical run \
  --projectId=$INFISICAL_PROJECT_ID \
  --token=$INFISICAL_TOKEN \
  --domain=$INFISICAL_DOMAIN \
  --env=<environment> \
  --path=</path/to/all/secrets> \
  -- talhelper genconfig
```

Replace:
- `<environment>`: Your Infisical environment (e.g., `dev`, `staging`, `prod`)
- `</path/to/all/secrets>`: The path in Infisical where your Talos secrets are stored (e.g., `/talos`)

### Example

For a production environment with secrets stored at `/talos`:

```bash
# Set token
export INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id=$INFISICAL_CLIENT_ID \
  --client-secret=$INFISICAL_CLIENT_SECRET \
  --projectId=$INFISICAL_PROJECT_ID \
  --domain=$INFISICAL_DOMAIN \
  --silent \
  --plain)

# Generate config
infisical run \
  --projectId=$INFISICAL_PROJECT_ID \
  --token=$INFISICAL_TOKEN \
  --domain=$INFISICAL_DOMAIN \
  --env=prod \
  --path=/talos \
  -- talhelper genconfig
```

## Directory Structure

```
.
├── README.md                    # This file
├── talconfig.yaml              # talhelper configuration
├── talsecret.yaml              # Secret templates (no actual values)
└── clusterconfig/              # Generated Talos configurations
    ├── omni-local-cluster-omni-local-cp1.yaml # contains secrets, gitignored
    └── talosconfig # contains secrets, gitignored
```

## Security Best Practices

- ✅ Never commit actual secret values to the repository
- ✅ Always use `.env` file for credentials and keep it out of version control
- ✅ Delete temporary secret files (`talsecret.temp.yaml`) immediately after storing in Infisical
- ✅ Use appropriate Infisical environments to separate dev/staging/prod secrets
- ✅ Regularly rotate your Infisical Client Secret
- ✅ Set appropriate access token TTL for your machine identity

## Troubleshooting

### Token Expiration

If you encounter authentication errors, your token may have expired. Re-run the login command to obtain a fresh token.

### Secret Name Mismatches

If talhelper fails to find secrets, ensure:
- Secret names in Infisical exactly match those referenced in `talsecret.yaml`
- You're pointing to the correct path in Infisical (`--path` flag)
- You're using the correct environment (`--env` flag)

### direnv Not Loading

If environment variables aren't available:
```bash
direnv allow
```

Then reload your shell or run:
```bash
source .envrc
```

## Resources

- [Infisical Documentation](https://infisical.com/docs/)
- [Infisical Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)
- [talhelper Documentation](https://budimanjojo.github.io/talhelper/)
- [Talos Documentation](https://www.talos.dev/)
