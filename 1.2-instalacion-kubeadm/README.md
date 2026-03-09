# 1.2 Instalación con Kubeadm

Scripts automatizados para instalar y configurar un clúster Kubernetes usando kubeadm.

## 📋 Scripts Disponibles

### `ubuntu.sh`
Instalación completa en Ubuntu (20.04+)
- containerd como container runtime
- kubeadm, kubelet, kubectl v1.30+
- Configuración de kernel y sysctl

### `rockylinux.sh`
Instalación completa en Rocky Linux (8+)
- containerd como container runtime
- kubeadm, kubelet, kubectl v1.30+
- Configuración de kernel y sysctl

### `setup-flannel.sh`
Instalación de Flannel CNI después de inicializar el clúster
- Pod CIDR: 10.244.0.0/16
- VXLAN overlay network

### `cleanup.sh`
Limpieza completa de componentes Kubernetes
- Elimina kubeadm, kubelet, kubectl
- Limpia configuraciones y datos
- Universal para cualquier distribución

## 🚀 Uso Rápido

### Control Plane

```bash
# 1. Instalar componentes
sudo bash ubuntu.sh  # o rockylinux.sh

# 2. Inicializar clúster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 3. Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Instalar CNI (ver módulo 1.3)
bash setup-flannel.sh
```

### Worker Nodes

```bash
# 1. Instalar componentes
sudo bash ubuntu.sh  # o rockylinux.sh

# 2. Unirse al clúster (usar token del control plane)
sudo kubeadm join <IP>:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

## 📚 Recursos

- [Documentación oficial kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Syllabus CKA - Módulo 1.2](https://cka.amxops.com)

---

**Parte del módulo 1.2 del Syllabus CKA 2026**

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
