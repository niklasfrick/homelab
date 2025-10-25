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
  @echo "🚀 Running generate command..."
  # Add your actual generate logic here
  @echo "✅ Generate completed"

