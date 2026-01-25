# Kubernetes Bastion Configuration

This guide explains how to configure remote access to a Kubernetes cluster from a bastion host.

## Prerequisites

- Kubernetes cluster already initialized
- Bastion host with Linux OS
- SSH access between bastion and master node
- Network connectivity between bastion and master node

## Method 1: Copy kubeconfig to Bastion (Recommended)

### On the Control Plane (Master Node)

```bash
# Copy the kubeconfig file to the bastion
scp /etc/kubernetes/admin.conf usuario@bastion-ip:~/.kube/config

# Alternative: Copy to temporary location first
cp /etc/kubernetes/admin.conf /tmp/kubeconfig
scp /tmp/kubeconfig usuario@bastion-ip:~/.kube/config
```

### On the Bastion Host

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Set proper permissions
chmod 600 ~/.kube/config

# Test the connection
kubectl get nodes
kubectl get pods --all-namespaces
```

## Method 2: SSH Tunnel (Most Secure)

### From the Bastion Host

```bash
# Create SSH tunnel to the master node
ssh -L 6443:localhost:6443 usuario@master-ip -N -f

# Configure kubeconfig to use localhost
kubectl config set-cluster kubernetes \
  --server=https://localhost:6443 \
  --kubeconfig=~/.kube/config

# Test connection
kubectl get nodes
```

### To stop the tunnel
```bash
# Find the tunnel process
ps aux | grep "ssh -L 6443"

# Kill the process
kill <PID>
```

## Method 3: Expose API Server Externally

### On the Control Plane

```bash
# Edit the kube-apiserver manifest
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml

# Add or modify these lines:
--advertise-address=<EXTERNAL-MASTER-IP>
--bind-address=0.0.0.0

# Restart the API server (it will restart automatically)
```

### Configure Firewall

```bash
# Open port 6443 on the master node
sudo ufw allow 6443/tcp
# or
sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT
```

### Configure kubeconfig for Remote Access

```bash
# Update the cluster server endpoint
kubectl config set-cluster kubernetes \
  --server=https://<MASTER-IP>:6443 \
  --kubeconfig=~/.kube/config

# If using self-signed certificates, you may need to skip TLS verification
kubectl config set-cluster kubernetes \
  --server=https://<MASTER-IP>:6443 \
  --kubeconfig=~/.kube/config \
  --insecure-skip-tls-verify=true
```

## Security Considerations

### Firewall Configuration
```bash
# On master node - restrict access to bastion IP only
sudo ufw allow from <BASTION-IP> to any port 6443 proto tcp
```

### RBAC Setup
```bash
# Create a service account for bastion access
kubectl create serviceaccount bastion-user

# Create cluster role binding
kubectl create clusterrolebinding bastion-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:bastion-user

# Get the token
kubectl create token bastion-user
```

### VPN Access (Recommended for Production)
- Set up a VPN between bastion and Kubernetes cluster
- Use WireGuard, OpenVPN, or cloud provider VPN solutions
- Ensures encrypted communication

## Troubleshooting

### Common Issues

1. **Connection Refused**
   ```bash
   # Check if API server is running
   sudo systemctl status kubelet
   
   # Check if port 6443 is open
   sudo netstat -tlnp | grep 6443
   ```

2. **Certificate Errors**
   ```bash
   # Check certificate validity
   openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
   
   # Skip TLS verification for testing (not recommended for production)
   kubectl get nodes --insecure-skip-tls-verify
   ```

3. **Permission Denied**
   ```bash
   # Check kubeconfig permissions
   ls -la ~/.kube/config
   
   # Should be 600
   chmod 600 ~/.kube/config
   ```

### Verification Commands

```bash
# Test basic connectivity
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check API server endpoint
kubectl config view --minify
```

## Best Practices

1. **Use SSH tunnels** for temporary access
2. **Implement proper RBAC** instead of using cluster-admin
3. **Use VPN** for production environments
4. **Regularly rotate certificates** and tokens
5. **Monitor access logs** on the API server
6. **Limit network access** using firewall rules

## Automation Script Example

```bash
#!/bin/bash
# bastion-setup.sh

BASTION_USER="usuario"
MASTER_IP="192.168.1.10"
BASTION_IP="192.168.1.100"

echo "Setting up kubectl on bastion..."

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Create kube directory
mkdir -p ~/.kube

# Copy config from master
scp ${BASTION_USER}@${MASTER_IP}:/etc/kubernetes/admin.conf ~/.kube/config

# Set permissions
chmod 600 ~/.kube/config

# Update server endpoint
kubectl config set-cluster kubernetes \
  --server=https://${MASTER_IP}:6443 \
  --kubeconfig=~/.kube/config

echo "Setup complete. Test with: kubectl get nodes"
```

This script can be run on the bastion host to automate the setup process.
