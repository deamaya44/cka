# CNI en Kubernetes - Laboratorios Prácticos

## Prerequisitos

Clúster Kubernetes funcional **sin CNI instalado**.

---

## Flannel

### Instalación
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get pods -n kube-flannel
kubectl get nodes
```

### Limpieza
```bash
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# En cada nodo (master + workers)
sudo rm -f /etc/cni/net.d/*
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo systemctl restart kubelet
```

---

## Calico

### Instalación
```bash
# Instalar operador
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

# Aplicar configuración (adapta CIDR si es necesario)
kubectl create -f manifests/calico-custom.yaml

# Monitorear
kubectl get pods -n calico-system
```

### Limpieza
```bash
kubectl delete -f manifests/calico-custom.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
```

---

## Weave Net

### Instalación
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
kubectl get pods -n kube-system -l name=weave-net
```

### Limpieza
```bash
kubectl delete -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
sudo rm -f /etc/cni/net.d/*
sudo ip link delete weave 2>/dev/null || true
sudo systemctl restart kubelet
```

---

## Labs

### Lab 1: Conectividad básica
```bash
kubectl run test1 --image=nginx
kubectl run test2 --image=nginx
kubectl wait --for=condition=Ready pod/test1 pod/test2

# Test conectividad
POD2_IP=$(kubectl get pod test2 -o jsonpath='{.status.podIP}')
kubectl exec test1 -- curl -s $POD2_IP | head -5

# Limpieza
kubectl delete pod test1 test2
```

### Lab 2: Test de rendimiento
```bash
kubectl apply -f manifests/iperf-test.yaml
kubectl wait --for=condition=Ready pod/iperf-server pod/iperf-client

# Ejecutar test
SERVER_IP=$(kubectl get pod iperf-server -o jsonpath='{.status.podIP}')
kubectl exec iperf-client -- iperf3 -c $SERVER_IP -t 10

# Limpieza
kubectl delete -f manifests/iperf-test.yaml
```

### Lab 3: Network Policies (solo Calico)
```bash
# Crear pods
kubectl apply -f manifests/policy-test-pods.yaml
kubectl wait --for=condition=Ready pod/web pod/client -n policy-test

# Test sin políticas
WEB_IP=$(kubectl get pod web -n policy-test -o jsonpath='{.status.podIP}')
kubectl run test1 --image=curlimages/curl -n policy-test --restart=Never -- curl -s $WEB_IP
kubectl logs test1 -n policy-test | head -3
kubectl delete pod test1 -n policy-test

# Aplicar deny
kubectl apply -f manifests/deny-policy.yaml
kubectl run test2 --image=curlimages/curl -n policy-test --restart=Never -- curl -s --connect-timeout 3 $WEB_IP
kubectl logs test2 -n policy-test || echo "BLOQUEADO"
kubectl delete pod test2 -n policy-test

# Aplicar allow
kubectl apply -f manifests/allow-policy.yaml
kubectl delete -f manifests/deny-policy.yaml
sleep 3
kubectl run test3 --image=curlimages/curl -n policy-test --restart=Never -- curl -s $WEB_IP
kubectl logs test3 -n policy-test | head -3
kubectl delete pod test3 -n policy-test

# Limpieza
kubectl delete namespace policy-test
```

### Lab 4: Troubleshooting
```bash
# Ver configuración CNI
cat /etc/cni/net.d/*.conflist

# Ver logs CNI
kubectl logs -n kube-system -l k8s-app=calico-node
kubectl logs -n kube-flannel -l app=flannel

# Ver rutas
ip route | grep -E 'cali|flannel|weave'
```
