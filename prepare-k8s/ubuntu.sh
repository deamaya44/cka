#!/bin/bash

# Script to install kubeadm and all necessary dependencies on Ubuntu
# This script sets up a Kubernetes cluster from scratch

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_status "Starting kubeadm installation on Ubuntu"

# Update system
print_status "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
print_status "Installing required packages..."
apt-get install -y curl wget vim git apt-transport-https ca-certificates gnupg lsb-release

# Disable swap (required for Kubernetes)
print_status "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required kernel modules
print_status "Loading kernel modules..."
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set required sysctl parameters
print_status "Configuring sysctl parameters..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Configure hostname resolution
print_status "Configuring hostname resolution..."
CURRENT_HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Add hostname to /etc/hosts if not already present
if ! grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    echo "$IP_ADDRESS $CURRENT_HOSTNAME" >> /etc/hosts
    print_status "Added $CURRENT_HOSTNAME to /etc/hosts"
fi

# Install container runtime (containerd)
print_status "Installing containerd..."
apt-get install -y containerd

# Create containerd configuration
print_status "Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Enable and start containerd
systemctl enable containerd
systemctl restart containerd

# Add Kubernetes repository
print_status "Adding Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update

# Install Kubernetes components
print_status "Installing kubelet, kubeadm, and kubectl..."
apt-get install -y kubelet kubeadm kubectl cri-tools kubernetes-cni
apt-mark hold kubelet kubeadm kubectl cri-tools kubernetes-cni

# Enable and start kubelet
systemctl enable kubelet
systemctl start kubelet

# Configure firewall
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 6443/tcp
    ufw allow 2379:2380/tcp
    ufw allow 10250/tcp
    ufw allow 10251/tcp
    ufw allow 10252/tcp
    ufw allow 179/tcp
    ufw allow 4789/udp
    ufw --force enable
else
    print_warning "ufw not found, please configure firewall manually"
fi

# Install additional useful tools
print_status "Installing additional tools..."
apt-get install -y bash-completion

# Enable bash completion for kubectl
print_status "Setting up kubectl bash completion..."
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# Verify installation
print_status "Verifying installation..."
if command -v kubeadm &> /dev/null; then
    print_status "kubeadm version: $(kubeadm version)"
else
    print_error "kubeadm not found"
    exit 1
fi

if command -v kubelet &> /dev/null; then
    print_status "kubelet version: $(kubelet --version)"
else
    print_error "kubelet not found"
    exit 1
fi

if command -v kubectl &> /dev/null; then
    print_status "kubectl version: $(kubectl version --client)"
else
    print_error "kubectl not found"
    exit 1
fi

# Check containerd status
if systemctl is-active --quiet containerd; then
    print_status "containerd is running"
else
    print_error "containerd is not running"
    exit 1
fi

print_status "Installation completed successfully!"
print_status "Next steps:"
print_status "1. Pull required images (recommended to avoid rate limiting): kubeadm config images pull"
print_status "2. Initialize the cluster: kubeadm init --pod-network-cidr=10.244.0.0/16"
print_status "3. Configure kubectl: mkdir -p \$HOME/.kube && cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
print_status "4. Install CNI plugin (Flannel): kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
print_status "5. Generate join command for worker nodes: kubeadm token create --print-join-command"
print_status "6. Join worker nodes using the token from step 5"
print_status ""
print_status "Or use the automated setup script after kubeadm init:"
print_status "./setup-flannel.sh"