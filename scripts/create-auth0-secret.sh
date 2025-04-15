#!/bin/bash
set -e

# Check if namespace exists, if not create it
if ! kubectl get namespace app &> /dev/null; then
  echo "Creating app namespace..."
  kubectl create namespace app
fi

# Check if the secret exists
if kubectl get secret auth0-credentials -n app &> /dev/null; then
  echo "Secret auth0-credentials already exists. Deleting it to update..."
  kubectl delete secret auth0-credentials -n app
fi

# Get values from ENV for Auth0 domain and audience
AUTH0_DOMAIN=${AUTH0_DOMAIN:-"https://dev-ev3swwjz7i8bem8j.us.auth0.com"}
AUTH0_AUDIENCE=${AUTH0_AUDIENCE:-"https://dev-ev3swwjz7i8bem8j.us.auth0.com/api/v2/"}

# Check if AUTH0_CLIENT_SECRET is set, if not prompt the user
if [ -z "$AUTH0_CLIENT_SECRET" ]; then
  echo "AUTH0_CLIENT_SECRET environment variable is not set."
  echo -n "Please enter your Auth0 Client Secret: "
  read -s AUTH0_CLIENT_SECRET
  echo ""
  
  if [ -z "$AUTH0_CLIENT_SECRET" ]; then
    echo "Error: Auth0 Client Secret is required. Please set the AUTH0_CLIENT_SECRET environment variable or provide it when prompted."
    exit 1
  fi
fi

# Create the Kubernetes secret
echo "Creating Auth0 credentials secret in Kubernetes..."
kubectl create secret generic auth0-credentials \
  --namespace=app \
  --from-literal=domain="$AUTH0_DOMAIN" \
  --from-literal=audience="$AUTH0_AUDIENCE" \
  --from-literal=client-secret="$AUTH0_CLIENT_SECRET"

echo "Auth0 credentials secret created successfully."
echo "Note: For security, the client secret is not displayed." 