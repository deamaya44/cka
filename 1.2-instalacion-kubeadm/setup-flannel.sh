#!/bin/bash

# Script to install Flannel CNI plugin for Kubernetes
# This script should be run after kubeadm init

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please configure kubectl first."
    print_status "Run: mkdir -p \$HOME/.kube && cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot access Kubernetes cluster. Please check kubectl configuration."
    exit 1
fi

print_status "Installing Flannel CNI plugin..."

# Apply Flannel manifest
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

print_status "Waiting for Flannel pods to be ready..."

# Wait for Flannel pods to be ready
kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s

print_status "Flannel CNI plugin installed successfully!"

# Verify installation
print_status "Verifying Flannel installation..."
kubectl get pods -n kube-flannel

# Check node status
print_status "Checking node status..."
kubectl get nodes

print_status "Flannel setup completed!"
print_status "Your cluster should now be ready with networking."
