# 1.3 Configuración de Red y CNI

Guías y laboratorios prácticos para instalar y configurar plugins CNI en Kubernetes.

## 📚 Contenido

- **README.md** - Guía teórica completa de CNI (conceptos, arquitectura, comparativas)
- **LABS.md** - Laboratorios prácticos paso a paso

## 🎯 Laboratorios Disponibles

1. **Verificar flujo CNI completo** - Entender cómo funciona CNI internamente
2. **Comparar rendimiento** - Benchmark con iperf3 entre diferentes CNIs
3. **Network Policies básicas** - Implementar políticas de red
4. **Troubleshooting CNI** - Diagnosticar problemas de red
5. **Network Policies multi-tier** - Aplicación completa con segmentación

## 🔧 CNIs Cubiertos

- **Flannel** - Overlay VXLAN simple
- **Calico** - L3 BGP con Network Policies avanzadas
- **Weave Net** - Mesh network con cifrado

## 🚀 Inicio Rápido

```bash
# Ver guía teórica
cat README.md

# Seguir laboratorios prácticos
cat LABS.md
```

## 📚 Recursos

- [Documentación CNI oficial](https://www.cni.dev/)
- [Syllabus CKA - Módulo 1.3](https://cka.amxops.com)

---

**Parte del módulo 1.3 del Syllabus CKA 2026**

---

## 📚 PARTE 1: Fundamentos de CNI

### ¿Qué es CNI (Container Network Interface)?

CNI es una **especificación abierta** mantenida por la CNCF que define cómo los plugins de red deben ser invocados por el runtime de contenedores (kubelet) para gestionar interfaces de red. No es un plugin en sí mismo: es el **contrato** que todos los plugins deben cumplir.

**Componentes clave:**
- **Especificación**: define el formato JSON de configuración y las operaciones soportadas.
- **Bibliotecas Go**: conjunto de utilidades para construir plugins compatibles.
- **Plugins de referencia**: bridge, loopback, host-device, etc.

**Las dos operaciones fundamentales de CNI:**
- `ADD` → Kubelet llama al plugin cuando un Pod nace. El plugin crea el par veth, asigna IP, configura rutas.
- `DEL` → Kubelet llama al plugin cuando un Pod muere. El plugin libera la IP y elimina la interfaz.

---

### El Modelo de Red de Kubernetes (los 4 requisitos)

Kubernetes exige una red "plana" que cumpla estas reglas sin excepciones:

| Requisito | Significado |
|---|---|
| **Pod-to-Pod sin NAT** | Cualquier Pod puede hablar con otro Pod usando su IP real, sin traducción de direcciones |
| **Node-to-Pod sin NAT** | Los nodos pueden contactar Pods directamente |
| **IP Real** | El Pod ve su propia IP tal como la ven los demás (no hay IP privada oculta) |
| **Flat Network** | Todas las IPs de Pods son únicas y ruteables en todo el clúster |

CNI es la herramienta que **implementa** estos requisitos.

---

### Cómo funciona CNI internamente (flujo paso a paso)

```
1. Se crea un Pod → kubelet detecta el nuevo sandbox
2. kubelet lee /etc/cni/net.d/<config>.conflist
3. kubelet ejecuta el binario del plugin en /opt/cni/bin/
4. El plugin crea un par veth (un extremo en el Pod, otro en el host)
5. El plugin asigna una IP del CIDR configurado (IPAM)
6. El plugin configura las rutas necesarias
7. El Pod queda conectado con eth0 y puede comunicarse
```

**Directorios importantes:**
```
/etc/cni/net.d/          # Archivos de configuración del plugin
/opt/cni/bin/            # Binarios del plugin
```

---

### Pod CIDR y Overlay Networks

**Pod CIDR**: rango de IPs reservado exclusivamente para los Pods del clúster.
- Ejemplo: `--pod-network-cidr=10.244.0.0/16` (Flannel por defecto)
- Cada nodo recibe una subred del Pod CIDR: Nodo 1 → `10.244.1.0/24`, Nodo 2 → `10.244.2.0/24`

**Overlay Network**: técnica donde el tráfico de red de los Pods se **encapsula** dentro del tráfico de la red física subyacente.
- El tráfico Pod→Pod se envuelve en paquetes UDP/IP normales (VXLAN)
- Ventaja: funciona sobre cualquier red sin configuración especial
- Desventaja: overhead de CPU por encapsulación/desencapsulación

**Underlay (routing puro)**: alternativa donde los Pods tienen IPs directamente ruteables en la red física (BGP). Calico lo hace así. Sin overhead, mayor rendimiento.

---

## 🛠️ PARTE 2: Prerequisitos del Laboratorio

Antes de instalar cualquier plugin necesitas un clúster Kubernetes funcional **sin CNI instalado**.

### Opción A: Clúster real con kubeadm (recomendado para aprender)

```bash
# En todos los nodos — deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Cargar módulos del kernel necesarios
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Parámetros sysctl para Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Instalar containerd
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Instalar kubeadm, kubelet, kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Opción B: kind (Kubernetes in Docker) — ideal para pruebas rápidas

```bash
# Instalar kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Crear clúster SIN CNI (para instalar el tuyo propio)
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
  podSubnet: "10.244.0.0/16"
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

kind create cluster --config kind-config.yaml --name cni-lab
kubectl cluster-info --context kind-cni-lab
```

### Opción C: minikube (una sola máquina, muy rápido)

```bash
# Instalar minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Arrancar con un CNI específico (minikube lo gestiona solo)
minikube start --cni=calico   # o flannel, cilium, etc.
```

---

## 🔴 PARTE 3: Instalación de Flannel

Flannel es el CNI más sencillo. Crea una red overlay VXLAN asignando una subred /24 a cada nodo.

### Arquitectura de Flannel

```
Nodo 1 (10.244.1.0/24)         Nodo 2 (10.244.2.0/24)
┌─────────────────────┐        ┌─────────────────────┐
│ Pod A: 10.244.1.2   │        │ Pod D: 10.244.2.2   │
│ Pod B: 10.244.1.3   │        │ Pod E: 10.244.2.3   │
│   ↕ veth pairs      │        │   ↕ veth pairs      │
│   cni0 bridge       │        │   cni0 bridge       │
│   flannel.1 (VXLAN) │◄──────►│   flannel.1 (VXLAN) │
└─────────────────────┘  UDP   └─────────────────────┘
                         8472
```

### Paso 1: Inicializar el clúster con el Pod CIDR correcto

```bash
# En el nodo control-plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# En los nodos worker — unirse al clúster (usar el token de kubeadm init)
sudo kubeadm join <IP_CONTROL_PLANE>:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

### Paso 2: Instalar Flannel

```bash
# Método recomendado: manifesto oficial
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verificar que los Pods de Flannel corren en todos los nodos
kubectl get pods -n kube-flannel
# Deberías ver un Pod por nodo en estado Running

# Verificar que los nodos pasan a Ready
kubectl get nodes
```

### Paso 3: Verificar la red

```bash
# Crear dos Pods de prueba
kubectl run pod1 --image=busybox --restart=Never -- sleep 3600
kubectl run pod2 --image=busybox --restart=Never -- sleep 3600

# Ver IPs asignadas
kubectl get pods -o wide

# Probar conectividad Pod-to-Pod
POD2_IP=$(kubectl get pod pod2 -o jsonpath='{.status.podIP}')
kubectl exec pod1 -- ping -c 3 $POD2_IP

# Inspeccionar la interfaz en el nodo
ip addr show flannel.1
ip route | grep flannel
```

### Personalizar el Pod CIDR de Flannel

```bash
# Descargar el manifesto para editarlo
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Buscar y cambiar el CIDR (línea Network en ConfigMap)
# "Network": "10.244.0.0/16"  → cambiar al CIDR deseado
kubectl apply -f kube-flannel.yml
```

---

## 🔵 PARTE 4: Instalación de Calico

Calico usa routing L3 con BGP (sin encapsulación) por defecto, ofreciendo mayor rendimiento y Network Policies nativas avanzadas.

### Arquitectura de Calico

```
Nodo 1                          Nodo 2
┌─────────────────────┐        ┌─────────────────────┐
│ Pod A: 192.168.1.2  │        │ Pod D: 192.168.2.2  │
│   ↕ veth (cali...)  │        │   ↕ veth (cali...)  │
│   BIRD daemon (BGP) │◄──BGP──►│   BIRD daemon (BGP) │
│   Felix (políticas) │        │   Felix (políticas) │
│   Typha (caché)     │        │   Typha (caché)     │
└─────────────────────┘        └─────────────────────┘
         ↑
    confd (genera configuración)
```

**Componentes de Calico:**
- **Felix**: agente que programa rutas e iptables/eBPF en cada nodo.
- **BIRD**: daemon BGP que distribuye información de rutas entre nodos.
- **Typha**: proxy de caché entre Felix y el API server (para clústeres grandes).
- **calico-kube-controllers**: sincroniza políticas de Kubernetes con Calico.

### Método 1: Operador Tigera (recomendado para producción)

```bash
# Paso 1: Inicializar kubeadm con el CIDR de Calico
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Paso 2: Instalar el operador Tigera
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

# Paso 3: Verificar que el operador esté corriendo
kubectl get pods -n tigera-operator

# Paso 4: Aplicar la configuración de Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# Paso 5: Monitorear la instalación
watch kubectl get pods -n calico-system

# Cuando todo esté Running:
kubectl get nodes  # Los nodos deben estar Ready
```

### Método 2: Manifiesto único (clústeres pequeños / labs)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# Si tu Pod CIDR no es 192.168.0.0/16, edita antes de aplicar:
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# Descomentar y editar estas líneas en el DaemonSet calico-node:
# - name: CALICO_IPV4POOL_CIDR
#   value: "10.244.0.0/16"   ← tu CIDR

kubectl apply -f calico.yaml
```

### Instalar calicoctl (herramienta de administración)

```bash
# Instalar calicoctl como plugin kubectl
curl -L https://github.com/projectcalico/calico/releases/download/v3.28.0/calicoctl-linux-amd64 \
  -o kubectl-calico
chmod +x kubectl-calico
sudo mv kubectl-calico /usr/local/bin/

# Verificar instalación
kubectl calico version

# Comandos útiles de calicoctl
kubectl calico get nodes          # Ver nodos en Calico
kubectl calico get ippools -o wide  # Ver pools de IPs
kubectl calico get bgppeers        # Ver peers BGP
```

### Crear Network Policies con Calico

```yaml
# deny-all.yaml — denegar todo el tráfico por defecto en un namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

```yaml
# allow-frontend-to-backend.yaml — permitir solo frontend → backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

```bash
kubectl apply -f deny-all.yaml
kubectl apply -f allow-frontend-to-backend.yaml

# Verificar políticas
kubectl get networkpolicies -n production
```

### GlobalNetworkPolicy de Calico (más potente que la estándar de K8s)

```yaml
# calico-global-policy.yaml
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: deny-egress-internet
spec:
  selector: app == "restricted"
  egress:
  - action: Allow
    destination:
      nets:
      - 10.0.0.0/8       # Solo tráfico interno
  - action: Deny
```

---

## 🟢 PARTE 5: Instalación de Weave Net

Weave crea una mesh network cifrada con auto-discovery entre nodos. Ideal para clústeres edge, IoT o situaciones donde el cifrado automático es prioritario.

### Arquitectura de Weave

```
Nodo 1                          Nodo 2
┌─────────────────────┐        ┌─────────────────────┐
│ Pod A: 10.32.0.1    │        │ Pod D: 10.44.0.1    │
│   ↕ veth            │        │   ↕ veth            │
│   weave bridge      │◄──────►│   weave bridge      │
│   weave daemon      │  Mesh  │   weave daemon      │
│   (auto-discovery)  │  6783  │   (auto-discovery)  │
└─────────────────────┘        └─────────────────────┘
```

**Puerto importante**: TCP/UDP 6783 y UDP 6784 deben estar abiertos entre nodos.

### Instalación de Weave Net

```bash
# Método 1: Manifesto directo
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# Método 2: Con configuración personalizada del CIDR
# Descargar y editar el CIDR (por defecto: 10.32.0.0/12)
curl -L https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml \
  -o weave-daemonset.yaml

# En el DaemonSet, agregar variable de entorno:
# - name: IPALLOC_RANGE
#   value: "10.244.0.0/16"

kubectl apply -f weave-daemonset.yaml

# Verificar Pods
kubectl get pods -n kube-system -l name=weave-net
```

### Habilitar cifrado en Weave

```bash
# Generar una contraseña para el cifrado
kubectl create secret -n kube-system generic weave-passwd \
  --from-literal=weave-passwd=$(openssl rand -hex 16)

# Descargar el manifesto y agregar referencia al secret:
# En el DaemonSet weave-net, contenedor weave:
# - name: WEAVE_PASSWORD
#   valueFrom:
#     secretKeyRef:
#       name: weave-passwd
#       key: weave-passwd

kubectl apply -f weave-daemonset.yaml
```

### Herramienta weave de diagnóstico

```bash
# Instalar weave CLI en cada nodo
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod +x /usr/local/bin/weave

# Comandos de diagnóstico
weave status           # Estado general de Weave
weave status peers     # Ver peers conectados
weave status dns       # Estado del DNS de Weave
weave ps               # Ver contenedores en la red Weave
weave report           # Informe completo (JSON)
```

---

## 🟡 PARTE 6: Bonus — Instalación de Cilium

Aunque la presentación lo menciona como "el futuro", aquí tienes su instalación completa.

### ¿Por qué eBPF es diferente?

Los CNIs tradicionales usan **iptables** para gestionar el tráfico. iptables procesa reglas secuencialmente: con 10.000 reglas es muy lento. eBPF ejecuta **programas directamente en el kernel** de forma eficiente, en tiempo O(1).

### Instalación con Helm (recomendado)

```bash
# Instalar Helm si no lo tienes
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Agregar repositorio de Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update

# Instalar Cilium
helm install cilium cilium/cilium --version 1.15.6 \
  --namespace kube-system \
  --set ipam.mode=kubernetes

# Monitorear instalación
kubectl -n kube-system rollout status ds/cilium

# Verificar estado
kubectl get pods -n kube-system -l k8s-app=cilium
```

### Instalar Cilium CLI

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all \
  https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin

# Test de conectividad (ejecuta ~60 pruebas de red)
cilium connectivity test
cilium status
```

### Instalar Hubble (observabilidad)

```bash
# Habilitar Hubble en la instalación de Cilium
helm upgrade cilium cilium/cilium --version 1.15.6 \
  --namespace kube-system \
  --reuse-values \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Port-forward para acceder a la UI
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 &
# Abrir: http://localhost:12000
```

---

## 🔄 PARTE 7: Cambiar de CNI (Migración)

Si quieres probar todos los plugins en el mismo clúster, debes eliminar el CNI actual antes de instalar uno nuevo.

```bash
# Paso 1: Eliminar el CNI actual (ejemplo: eliminar Flannel)
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Paso 2: Limpiar configuración CNI en CADA NODO
sudo rm -f /etc/cni/net.d/*
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true

# Para Calico
sudo ip link delete tunl0 2>/dev/null || true
sudo ip link delete vxlan.calico 2>/dev/null || true

# Para Weave
sudo ip link delete weave 2>/dev/null || true

# Paso 3: Reiniciar kubelet en todos los nodos
sudo systemctl restart kubelet

# Paso 4: Verificar que los nodos están NotReady (sin CNI)
kubectl get nodes

# Paso 5: Instalar el nuevo CNI
kubectl apply -f <nuevo-cni.yaml>

# Paso 6: Reiniciar todos los Pods del sistema para reasignar IPs
kubectl delete pods --all -n kube-system
```

---

## 🧪 PARTE 8: Laboratorio Práctico Completo

### Lab 1: Verificar el flujo CNI completo

```bash
# Ver qué CNI está configurado
cat /etc/cni/net.d/*.conflist  # o .conf

# Ver los binarios disponibles
ls /opt/cni/bin/

# Crear un Pod y seguir su creación paso a paso
kubectl run test --image=nginx
kubectl describe pod test   # Ver eventos de red
kubectl get pod test -o jsonpath='{.status.podIP}'
```

### Lab 2: Comparar rendimiento entre plugins

```bash
# Instalar iperf3
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

### Lab 3: Probar Network Policies (requiere Calico o Cilium)

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
```

---

## 📊 PARTE 9: Tabla Comparativa Extendida

| Característica | Flannel | Calico | Weave Net | Cilium |
|---|---|---|---|---|
| **Tipo de Red** | Overlay VXLAN | L3 BGP / VXLAN | Mesh Overlay | eBPF / VXLAN |
| **Network Policies** | ✗ No | ✓ Nativas L3-L4 | ✓ Básicas | ✓ L3-L7 |
| **Rendimiento** | Medio | Alto | Medio | Muy Alto |
| **Complejidad** | Baja | Media | Baja | Alta |
| **Cifrado** | ✗ | WireGuard | ✓ NaCl automático | WireGuard/IPsec |
| **Observabilidad** | Básica | Buena | Buena | Excelente (Hubble) |
| **IPAM avanzado** | ✗ | ✓ por NS/nodo | ✗ | ✓ |
| **IPv6** | Parcial | ✓ Dual-stack | ✓ | ✓ |
| **eBPF** | ✗ | Opcional | ✗ | ✓ Nativo |
| **BGP** | ✗ | ✓ Nativo | ✗ | ✗ |
| **Caso ideal** | Dev/Test/Lab | Producción enterprise | Edge/IoT/pequeños | Telco/alta performance |

---

## 🎯 PARTE 10: Preguntas Frecuentes de Examen/Entrevista

**¿Puede haber dos CNIs instalados a la vez?**
No de forma simultánea para el mismo clúster. Se puede usar un "meta-plugin" como Multus para adjuntar interfaces adicionales a los Pods, pero solo un CNI primario gestiona la red principal.

**¿Qué pasa si no instalas ningún CNI?**
Los nodos se quedan en estado `NotReady` y los Pods no pueden comunicarse entre sí. El CoreDNS y otros componentes del sistema no arrancarán.

**¿Por qué Flannel no soporta Network Policies?**
Flannel solo gestiona la conectividad (asignación de IPs y rutas). Las Network Policies requieren que el CNI integre un motor de políticas (como Felix en Calico). Puedes combinar Flannel + un controlador de Network Policies externo, pero no es habitual.

**¿Cuál es la diferencia entre VXLAN y BGP?**
VXLAN encapsula los paquetes de red dentro de UDP (overlay). BGP anuncia las rutas de los Pods a todos los nodos como si fueran rutas de red reales (underlay). BGP tiene menos overhead pero requiere que la red física soporte las rutas (o un router BGP).

**¿Qué es el Pod CIDR y por qué importa elegirlo bien?**
Es el rango de IPs para todos los Pods del clúster. Debe ser lo suficientemente grande para todos los Pods futuros, no solaparse con la red del clúster ni con redes externas, y ser elegido antes de crear el clúster (no se puede cambiar fácilmente después).

---

*Guía generada basada en la presentación CNI_Kubernetes.pptx — Claude, Febrero 2026*
