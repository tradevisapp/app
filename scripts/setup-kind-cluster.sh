#!/bin/bash
# Create and configure Kind cluster

echo "Creating Kind cluster..."
sudo kind create cluster --name tradevis-cluster --config kind-config.yaml

# Set kubectl context to use the Kind cluster
echo "Setting kubectl context to use the Kind cluster..."
sudo kubectl config use-context kind-tradevis-cluster

# Verify cluster is running
sudo kubectl cluster-info --context kind-tradevis-cluster
echo "Kind cluster created successfully" 