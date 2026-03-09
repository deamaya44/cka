# 🌐 CNI en Kubernetes - Laboratorios Prácticos

## 📋 Prerequisitos

Clúster Kubernetes funcional **sin CNI instalado**.

### Preparar el clúster (todos los nodos)

```bash
# Deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Cargar módulos del kernel
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Parámetros sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

---

## 🔴 Flannel - Instalación y Limpieza

### Instalación

```bash
# Inicializar control plane con Pod CIDR correcto
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verificar
kubectl get pods -n kube-flannel
kubectl get nodes
```

### Limpieza

```bash
# Eliminar Flannel
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Limpiar en CADA NODO
sudo rm -f /etc/cni/net.d/*
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo systemctl restart kubelet
```

---

## 🔵 Calico - Instalación y Limpieza

### Instalación (Operador Tigera)

```bash
# Inicializar con CIDR de Calico
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Instalar operador
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

# Aplicar configuración
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# Monitorear
watch kubectl get pods -n calico-system
```

### Instalar calicoctl

```bash
curl -L https://github.com/projectcalico/calico/releases/download/v3.28.0/calicoctl-linux-amd64 \
  -o kubectl-calico
chmod +x kubectl-calico
sudo mv kubectl-calico /usr/local/bin/

# Verificar
kubectl calico version
kubectl calico get nodes
```

### Limpieza

```bash
# Eliminar Calico
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

# Limpiar en CADA NODO
sudo rm -f /etc/cni/net.d/*
sudo ip link delete tunl0 2>/dev/null || true
sudo ip link delete vxlan.calico 2>/dev/null || true
sudo systemctl restart kubelet
```

---

## 🟢 Weave Net - Instalación y Limpieza

### Instalación

```bash
# Instalar Weave
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Verificar
kubectl get pods -n kube-system -l name=weave-net
```

### Limpieza

```bash
# Eliminar Weave
kubectl delete -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Limpiar en CADA NODO
sudo rm -f /etc/cni/net.d/*
sudo ip link delete weave 2>/dev/null || true
sudo systemctl restart kubelet
```

---

## 🧪 Laboratorios Prácticos

### Lab 1: Verificar el flujo CNI completo

```bash
# Ver qué CNI está configurado
cat /etc/cni/net.d/*.conflist

# Ver binarios disponibles
ls /opt/cni/bin/

# Crear Pod y seguir su creación
kubectl run test --image=nginx
kubectl describe pod test
kubectl get pod test -o jsonpath='{.status.podIP}'

# Verificar conectividad
kubectl run test2 --image=nginx
POD2_IP=$(kubectl get pod test2 -o jsonpath='{.status.podIP}')
kubectl exec test -- curl -s $POD2_IP
```

---

### Lab 2: Comparar rendimiento entre plugins

```bash
# Crear servidor y cliente iperf3
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: iperf-server
spec:
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    command: ["iperf3", "-s"]
---
apiVersion: v1
kind: Pod
metadata:
  name: iperf-client
spec:
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    command: ["sleep", "infinity"]
EOF

# Obtener IP del servidor
SERVER_IP=$(kubectl get pod iperf-server -o jsonpath='{.status.podIP}')

# Ejecutar test de rendimiento
kubectl exec iperf-client -- iperf3 -c $SERVER_IP -t 10

# Comparar resultados entre diferentes CNIs
```

**Resultados esperados:**
- Flannel (VXLAN): ~8-9 Gbps
- Calico (BGP): ~9-10 Gbps
- Weave: ~7-8 Gbps

---

### Lab 3: Probar Network Policies (Calico o Cilium)

```bash
# Crear namespace con pods
kubectl create namespace policy-test

# Crear servidor web
kubectl run web --image=nginx -n policy-test --labels="app=web"
kubectl expose pod web --port=80 -n policy-test

# Crear cliente
kubectl run client --image=busybox -n policy-test -- sleep 3600

# Sin políticas: debe funcionar
kubectl exec -n policy-test client -- wget -qO- web

# Aplicar deny-all
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: policy-test
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
EOF

# Ahora debe fallar (timeout)
kubectl exec -n policy-test client -- wget -qO- --timeout=5 web

# Permitir acceso del cliente al web
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-web
  namespace: policy-test
spec:
  podSelector:
    matchLabels:
      run: web
  ingress:
  - from:
    - podSelector:
        matchLabels:
          run: client
EOF

# Ahora debe funcionar de nuevo
kubectl exec -n policy-test client -- wget -qO- web

# Limpieza
kubectl delete namespace policy-test
```

---

### Lab 4: Troubleshooting CNI

```bash
# Verificar estado de CNI
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl logs -n kube-system -l k8s-app=calico-node

# Ver configuración CNI
cat /etc/cni/net.d/*.conflist | jq '.'

# Verificar rutas en el nodo
ip route | grep cali
ip addr show | grep cali

# Verificar iptables (Calico)
sudo iptables -t nat -L -n | grep cali

# Test de conectividad DNS
kubectl run dnstest --image=busybox --restart=Never -- sleep 3600
kubectl exec dnstest -- nslookup kubernetes.default
kubectl delete pod dnstest
```

---

### Lab 5: Network Policy Avanzada

```bash
# Crear aplicación multi-tier
kubectl create namespace app

# Frontend
kubectl run frontend --image=nginx -n app --labels="tier=frontend"
kubectl expose pod frontend --port=80 -n app

# Backend
kubectl run backend --image=nginx -n app --labels="tier=backend"
kubectl expose pod backend --port=80 -n app

# Database
kubectl run database --image=nginx -n app --labels="tier=database"
kubectl expose pod database --port=80 -n app

# Política: Frontend → Backend (permitir)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: app
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
EOF

# Política: Backend → Database (permitir)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-to-database
  namespace: app
spec:
  podSelector:
    matchLabels:
      tier: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
EOF

# Política: Denegar todo lo demás
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Probar conectividad
# Frontend → Backend: OK
kubectl exec -n app frontend -- curl -s backend

# Frontend → Database: FAIL
kubectl exec -n app frontend -- curl -s --max-time 5 database

# Backend → Database: OK
kubectl exec -n app backend -- curl -s database

# Limpieza
kubectl delete namespace app
```

---

## 📊 Tabla Comparativa

| CNI | Tipo | Network Policies | Rendimiento | Complejidad |
|---|---|---|---|---|
| **Flannel** | Overlay VXLAN | ✗ | Medio | Baja |
| **Calico** | L3 BGP | ✓ Nativas | Alto | Media |
| **Weave** | Mesh Overlay | ✓ Básicas | Medio | Baja |

---

## 🎯 Comandos de Troubleshooting

```bash
# Ver estado de nodos
kubectl get nodes -o wide

# Ver Pods de CNI
kubectl get pods -n kube-system -l k8s-app=<cni-name>

# Logs de CNI
kubectl logs -n kube-system <cni-pod-name>

# Verificar configuración CNI
cat /etc/cni/net.d/*.conflist

# Ver interfaces de red
ip addr show
ip route

# Test de conectividad Pod-to-Pod
kubectl run test1 --image=busybox -- sleep 3600
kubectl run test2 --image=busybox -- sleep 3600
kubectl exec test1 -- ping -c 3 $(kubectl get pod test2 -o jsonpath='{.status.podIP}')

# Test DNS
kubectl exec test1 -- nslookup kubernetes.default
```

---

**Guía práctica para el módulo 1.3 del Syllabus CKA 2026**
