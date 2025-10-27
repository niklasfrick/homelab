set dotenv-load

# Check if .env file exists and contains required variables
preflight-check:
  #!/usr/bin/env bash
  set -e
  
  # Required environment variables
  REQUIRED_VARS=("INFISICAL_CLIENT_ID" "INFISICAL_CLIENT_SECRET" "INFISICAL_PROJECT_ID" "INFISICAL_API_URL")
  
  if [ ! -f .env ]; then
    echo "❌ .env file not found"
    echo "Creating .env file with required variables..."
    just create-env
    exit 0
  fi
  
  echo "✅ .env file found"
  
  # Check if all required variables are set
  missing_vars=()
  for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${var}=" .env || [ -z "$(grep "^${var}=" .env | cut -d'=' -f2)" ]; then
      missing_vars+=("$var")
    fi
  done
  
  if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
      echo "  - $var"
    done
    echo "Please update your .env file with the missing variables."
    exit 1
  fi
  
  echo "✅ All required environment variables are set"

# Create .env file interactively
create-env:
  #!/usr/bin/env bash
  echo "Creating .env file..."
  echo "# Infisical Configuration" > .env
  echo "# Generated on $(date)" >> .env
  echo "" >> .env
  
  # Get INFISICAL_CLIENT_ID
  read -p "Enter INFISICAL_CLIENT_ID: " client_id
  echo "INFISICAL_CLIENT_ID=$client_id" >> .env
  
  # Get INFISICAL_CLIENT_SECRET
  read -p "Enter INFISICAL_CLIENT_SECRET: " client_secret
  echo "INFISICAL_CLIENT_SECRET=$client_secret" >> .env
  
  # Get INFISICAL_PROJECT_ID
  read -p "Enter INFISICAL_PROJECT_ID: " project_id
  echo "INFISICAL_PROJECT_ID=$project_id" >> .env
  
  # Get INFISICAL_API_URL
  read -p "Enter INFISICAL_API_URL (default: https://app.infisical.com): " api_url
  if [ -z "$api_url" ]; then
    api_url="https://app.infisical.com"
  fi
  echo "INFISICAL_API_URL=$api_url" >> .env
  
  echo "✅ .env file created successfully"

# Main generate command that runs preflight check first
generate: preflight-check
  #!/usr/bin/env bash
  set -e
  
  echo "🚀 Running generate command..."
  
  # Change to the talos config directory
  cd clusters/omni-local/talos-config
  
  echo "📡 Authenticating with Infisical..."
  export INFISICAL_TOKEN=$(infisical login \
    --method=universal-auth \
    --client-id=$INFISICAL_CLIENT_ID \
    --client-secret=$INFISICAL_CLIENT_SECRET \
    --silent \
    --plain)
  
  if [ -z "$INFISICAL_TOKEN" ]; then
    echo "❌ Failed to obtain Infisical token"
    exit 1
  fi
  
  echo "✅ Authenticated successfully"
  echo "🔧 Generating Talos configuration..."
  
  infisical run \
    --projectId=$INFISICAL_PROJECT_ID \
    --token=$INFISICAL_TOKEN \
    --env=prod \
    --path=/omni/omni-local-cluster \
    -- talhelper genconfig
  
  echo "✅ Talos configuration generated successfully!"
  echo "📁 Configuration files are in: clusters/omni-local/talos-config/clusterconfig/"

# Apply Talos configuration to all nodes
apply-config:
  #!/usr/bin/env bash
  set -e
  
  echo "🚀 Applying Talos configuration to all nodes..."
  
  # Change to the talos config directory
  cd clusters/omni-local/talos-config
  
  # Extract cluster name from talconfig.yaml
  CLUSTER_NAME=$(yq eval '.clusterName' talconfig.yaml)
  
  # Get the list of nodes and apply configuration to each
  yq eval '.nodes[] | [.hostname, .ipAddress] | join(" ")' talconfig.yaml | while read -r hostname ipAddress; do
    CONFIG_FILE="clusterconfig/${CLUSTER_NAME}-${hostname}.yaml"
    
    if [ ! -f "$CONFIG_FILE" ]; then
      echo "❌ Config file not found: $CONFIG_FILE"
      exit 1
    fi
    
    echo "📡 Applying configuration to node: $hostname ($ipAddress)"
    talosctl apply-config --nodes "$ipAddress" --file "$CONFIG_FILE"
    echo "✅ Configuration applied to $hostname"
  done
  
  echo "✅ All configurations applied successfully!"
