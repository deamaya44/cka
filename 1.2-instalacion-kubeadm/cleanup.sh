#!/bin/bash

# Universal Kubernetes cleanup script for any Linux distribution
# This script removes all Kubernetes components and configurations

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

print_status "Starting Kubernetes cleanup process"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    REMOVE_CMD="apt-get remove --purge -y"
    AUTOREMOVE_CMD="apt-get autoremove -y"
    CLEAN_CMD="apt-get clean"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    REMOVE_CMD="dnf remove -y"
    AUTOREMOVE_CMD="dnf autoremove -y"
    CLEAN_CMD="dnf clean all"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    REMOVE_CMD="yum remove -y"
    AUTOREMOVE_CMD="yum autoremove -y"
    CLEAN_CMD="yum clean all"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
    REMOVE_CMD="zypper remove -y"
    AUTOREMOVE_CMD="zypper packages --unneeded"
    CLEAN_CMD="zypper clean"
else
    print_error "Unsupported package manager. Only apt, dnf, yum, and zypper are supported."
    exit 1
fi

print_status "Detected package manager: $PKG_MANAGER"

# Stop Kubernetes services
print_status "Stopping Kubernetes services..."
systemctl stop kubelet 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true
systemctl stop docker 2>/dev/null || true

# Disable Kubernetes services
print_status "Disabling Kubernetes services..."
systemctl disable kubelet 2>/dev/null || true
systemctl disable containerd 2>/dev/null || true
systemctl disable docker 2>/dev/null || true

# Remove Kubernetes packages
print_status "Removing Kubernetes packages..."
$REMOVE_CMD kubeadm kubectl kubelet cri-tools kubernetes-cni 2>/dev/null || true

# Remove container runtime
print_status "Removing container runtime..."
$REMOVE_CMD containerd containerd.io docker docker.io docker-ce docker-ce-cli runc 2>/dev/null || true

# Remove additional packages
print_status "Removing additional packages..."
$REMOVE_CMD containerd runc 2>/dev/null || true

# Autoremove unused packages
print_status "Removing unused packages..."
$AUTOREMOVE_CMD 2>/dev/null || true

# Clean package cache
print_status "Cleaning package cache..."
$CLEAN_CMD 2>/dev/null || true

# Remove Kubernetes configuration files
print_status "Removing Kubernetes configuration files..."
rm -rf /etc/kubernetes 2>/dev/null || true
rm -rf /var/lib/kubelet 2>/dev/null || true
rm -rf /var/lib/etcd 2>/dev/null || true
rm -rf /var/lib/kube-proxy 2>/dev/null || true
rm -rf /var/lib/cni 2>/dev/null || true
rm -rf /etc/cni 2>/dev/null || true
rm -rf /opt/cni 2>/dev/null || true

# Remove container runtime configuration
print_status "Removing container runtime configuration..."
rm -rf /etc/containerd 2>/dev/null || true
rm -rf /etc/docker 2>/dev/null || true
rm -rf /var/lib/containerd 2>/dev/null || true
rm -rf /var/lib/docker 2>/dev/null || true

# Remove Kubernetes repository files
print_status "Removing Kubernetes repository files..."
rm -f /etc/apt/sources.list.d/kubernetes.list 2>/dev/null || true
rm -f /etc/yum.repos.d/kubernetes.repo 2>/dev/null || true
rm -f /etc/zypp/repos.d/kubernetes.repo 2>/dev/null || true
rm -f /etc/zypp/repos.d/kubernetes.repo 2>/dev/null || true

# Remove Docker repository files
print_status "Removing Docker repository files..."
rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
rm -f /etc/yum.repos.d/docker-ce.repo 2>/dev/null || true
rm -f /etc/yum.repos.d/docker-ce-stable.repo 2>/dev/null || true

# Remove GPG keys
print_status "Removing Kubernetes and Docker GPG keys..."
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || true
rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-kubernetes 2>/dev/null || true
rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-docker 2>/dev/null || true

# Remove systemd unit files
print_status "Removing systemd unit files..."
rm -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 2>/dev/null || true
rm -f /etc/systemd/system/kubelet.service 2>/dev/null || true

# Reload systemd
print_status "Reloading systemd..."
systemctl daemon-reload

# Reset iptables (optional)
print_status "Resetting iptables rules..."
iptables -F 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -X 2>/dev/null || true

# Remove IPVS rules
print_status "Removing IPVS rules..."
ipvsadm --clear 2>/dev/null || true

# Remove kernel modules
print_status "Removing kernel modules..."
modprobe -r br_netfilter 2>/dev/null || true
modprobe -r overlay 2>/dev/null || true

# Remove sysctl configuration
print_status "Removing sysctl configuration..."
rm -f /etc/sysctl.d/k8s.conf 2>/dev/null || true
rm -f /etc/modules-load.d/k8s.conf 2>/dev/null || true

# Reset sysctl
sysctl --system 2>/dev/null || true

# Remove CNI interfaces
print_status "Removing CNI network interfaces..."
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete weave-net 2>/dev/null || true

# Remove Flannel namespace and resources
print_status "Removing Flannel CNI resources..."
kubectl delete namespace kube-flannel 2>/dev/null || true
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml 2>/dev/null || true

# Remove remaining Kubernetes processes
print_status "Terminating remaining Kubernetes processes..."
pkill -f kubelet 2>/dev/null || true
pkill -f kube-proxy 2>/dev/null || true
pkill -f containerd 2>/dev/null || true
pkill -f docker 2>/dev/null || true

# Remove log files
print_status "Removing log files..."
rm -rf /var/log/kubelet 2>/dev/null || true
rm -rf /var/log/pods 2>/dev/null || true
rm -rf /var/log/containers 2>/dev/null || true

# Clean up remaining directories
print_status "Cleaning up remaining directories..."
rm -rf /run/flannel 2>/dev/null || true
rm -rf /run/kubelet 2>/dev/null || true
rm -rf /run/containerd 2>/dev/null || true
rm -rf /run/docker 2>/dev/null || true

# Re-enable swap if it was disabled
print_status "Re-enabling swap..."
swapon -a 2>/dev/null || true

# Remove swap configuration from fstab (comment out)
print_status "Updating fstab..."
sed -i 's/^.*swap.*/#&/' /etc/fstab 2>/dev/null || true

# Remove bash completion entries
print_status "Removing bash completion entries..."
sed -i '/source <(kubectl completion bash)/d' ~/.bashrc 2>/dev/null || true
sed -i '/alias k=kubectl/d' ~/.bashrc 2>/dev/null || true
sed -i '/complete -F __start_kubectl k/d' ~/.bashrc 2>/dev/null || true

# Remove kubectl aliases from current session
unset -f kubectl 2>/dev/null || true
unalias k 2>/dev/null || true

print_status "Cleanup completed successfully!"
print_warning "Please reboot the system to ensure all changes take effect."
print_status "After reboot, you can run the installation script again."

# Final verification
print_status "Performing final verification..."

if command -v kubeadm &> /dev/null; then
    print_warning "kubeadm is still installed. Manual removal may be required."
else
    print_status "kubeadm has been successfully removed."
fi

if command -v kubectl &> /dev/null; then
    print_warning "kubectl is still installed. Manual removal may be required."
else
    print_status "kubectl has been successfully removed."
fi

if command -v kubelet &> /dev/null; then
    print_warning "kubelet is still installed. Manual removal may be required."
else
    print_status "kubelet has been successfully removed."
fi

if command -v containerd &> /dev/null; then
    print_warning "containerd is still installed. Manual removal may be required."
else
    print_status "containerd has been successfully removed."
fi

print_status "Cleanup process finished. System is ready for fresh Kubernetes installation."
