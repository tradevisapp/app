#!/bin/bash

# Function to get input with optional default value
get_input() {
  local prompt="$1"
  local default="$2"
  local value=""
  
  if [ -n "$default" ]; then
    echo -n "$prompt [$default]: "
  else
    echo -n "$prompt: "
  fi
  
  read value
  if [ -z "$value" ] && [ -n "$default" ]; then
    value="$default"
  fi
  
  echo "$value"
}

# Function to get secret input
get_secret_input() {
  local prompt="$1"
  local value=""
  
  echo -n "$prompt: "
  read -s value
  echo ""
  
  echo "$value"
}

echo "Auth0 Credentials Setup Script"
echo "============================="
echo "This script will help you set up the required Auth0 credentials."
echo "You can press Enter to use the default values for domain and audience."
echo ""

# Get Auth0 Domain
default_domain="https://dev-ev3swwjz7i8bem8j.us.auth0.com"
AUTH0_DOMAIN=$(get_input "Enter your Auth0 Domain" "$default_domain")

# Get Auth0 Audience
default_audience="https://dev-ev3swwjz7i8bem8j.us.auth0.com/api/v2/"
AUTH0_AUDIENCE=$(get_input "Enter your Auth0 Audience" "$default_audience")

# Get Auth0 Client Secret (no default, required)
AUTH0_CLIENT_SECRET=$(get_secret_input "Enter your Auth0 Client Secret (input hidden)")

if [ -z "$AUTH0_CLIENT_SECRET" ]; then
  echo "Error: Auth0 Client Secret is required."
  exit 1
fi

# Create or update .env file
cat > .env << EOF
# Auth0 Credentials
AUTH0_DOMAIN=$AUTH0_DOMAIN
AUTH0_AUDIENCE=$AUTH0_AUDIENCE
AUTH0_CLIENT_SECRET=$AUTH0_CLIENT_SECRET
EOF

echo ""
echo "Auth0 credentials have been saved to .env file."
echo "To use these credentials in your current shell, run:"
echo ""
echo "  export AUTH0_DOMAIN=\"$AUTH0_DOMAIN\""
echo "  export AUTH0_AUDIENCE=\"$AUTH0_AUDIENCE\""
echo "  export AUTH0_CLIENT_SECRET=\"[hidden]\""
echo ""
echo "Or simply run: source .env"
echo ""
echo "Note: For security, the client secret is not displayed." 