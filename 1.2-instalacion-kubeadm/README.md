# 1.2 Instalación con Kubeadm

Scripts de instalación automatizada para clústeres Kubernetes con kubeadm.

## Scripts

**ubuntu.sh**  
Instalación completa en Ubuntu 20.04+. Incluye containerd, kubeadm, kubelet, kubectl v1.30+.

**rockylinux.sh**  
Instalación completa en Rocky Linux 8+. Incluye containerd, kubeadm, kubelet, kubectl v1.30+.

**setup-flannel.sh**  
Instalación de Flannel CNI post-init. Pod CIDR: 10.244.0.0/16.

**cleanup.sh**  
Limpieza completa de componentes Kubernetes. Universal para cualquier distribución.

## Uso

### Control Plane

```bash
# Instalar componentes
sudo bash ubuntu.sh

# Inicializar clúster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar CNI (ver módulo 1.3)
bash setup-flannel.sh
```

### Worker Nodes

```bash
# Instalar componentes
sudo bash ubuntu.sh

# Unirse al clúster
sudo kubeadm join <IP>:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

## Referencias

- [kubeadm documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Syllabus CKA - Módulo 1.2](https://cka.amxops.com)

---

*Módulo 1.2 del Syllabus CKA 2026*
