#!/bin/bash

echo "Updating system packages..."

# Update package lists
sudo apt-get update

# Upgrade packages
sudo apt-get upgrade -y

echo "System update completed." 