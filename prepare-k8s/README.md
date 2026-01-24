# Kubernetes Cluster Preparation Scripts

This directory contains scripts to install and configure all necessary components for setting up a Kubernetes cluster using kubeadm on different Linux distributions.

### Scripts

### Ubuntu Installation (`ubuntu.sh`)
Automated script to install kubeadm, kubelet, kubectl, and containerd on Ubuntu systems.

### Rocky Linux Installation (`rockylinux.sh`)
Automated script to install kubeadm, kubelet, kubectl, and containerd on Rocky Linux systems.

### CNI Setup (`setup-flannel.sh`)
Automated script to install Flannel CNI plugin after cluster initialization.

### Cleanup (`cleanup.sh`)
Universal script to completely remove Kubernetes components from any Linux distribution.

## What Gets Installed

### Core Components
- **containerd**: Container runtime for Kubernetes
- **kubelet**: Node agent that runs on each node
- **kubeadm**: Tool to bootstrap the cluster
- **kubectl**: Command line tool for interacting with the cluster

### Additional Tools
- **cri-tools**: Container Runtime Interface tools
- **kubernetes-cni**: Container Networking Interface plugins
- **bash-completion**: Command completion support

**Post-Installation Steps**

After running the appropriate script for your system:

1. **Pull required images (recommended to avoid rate limiting):**
   ```bash
   sudo kubeadm config images pull
   ```

2. **Initialize the cluster (on master node):**
   ```bash
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   ```

3. **Configure kubectl for regular user:**
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

4. **Install a CNI plugin (example with Flannel):**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
   ```

5. **Join worker nodes:**
   Use the `kubeadm join` command provided after cluster initialization on each worker node.

## Network Ports

The scripts configure the following firewall ports:
- **6443/tcp**: Kubernetes API server
- **2379-2380/tcp**: etcd server client API
- **10250/tcp**: Kubelet API
- **10251/tcp**: kube-scheduler
- **10252/tcp**: kube-controller-manager
- **179/tcp**: BGP (for some CNI plugins)
- **4789/udp**: VXLAN (for overlay networks)

## Troubleshooting

### Common Issues

1. **Swap not disabled**: Ensure swap is completely disabled and removed from `/etc/fstab`
2. **Containerd not running**: Check with `systemctl status containerd`
3. **Kubelet not starting**: Check logs with `journalctl -xeu kubelet`
4. **Firewall blocking**: Verify required ports are open
5. **Memory requirements**: Minimum 2GB RAM recommended

### Verification Commands

```bash
# Check containerd status
sudo systemctl status containerd

# Check kubelet status
sudo systemctl status kubelet

# Verify kubeadm installation
kubeadm version

# Check cluster nodes (after initialization)
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

## Security Considerations

- Scripts must be run with root privileges
- Kubernetes components are held at their current version to prevent automatic updates
- Firewall rules are configured to allow only necessary Kubernetes ports
- Consider using a dedicated user for Kubernetes administration

## Support

For issues related to:
- **Script execution**: Check system logs and ensure all prerequisites are met
- **Kubernetes cluster**: Refer to official Kubernetes documentation
- **Container runtime**: Check containerd logs and configuration

## Kubernetes Version

The scripts install Kubernetes v1.35.x (latest stable). To use a different version, modify the repository URLs in the scripts accordingly.
