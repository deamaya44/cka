# CKA Study Group - Certified Kubernetes Administrator Preparation

Collaborative study space for group members preparing together for the Kubernetes Administrator certification. We'll advance collectively and update this repository progressively as we master each topic.

📍 **Current Progress:** Module 1.3 - Configuración de Red y CNI

## Study Roadmap

Seguimos el [Syllabus Oficial CKA 2026](https://cka.amxops.com) con enfoque práctico y laboratorios hands-on.

### ✅ Completado

#### 1.1 Arquitectura del Clúster Kubernetes
- ✓ Control Plane components (API Server, etcd, Scheduler, Controller Manager)
- ✓ Worker Nodes (kubelet, kube-proxy, container runtime)
- ✓ Kubernetes API Primitives

#### 1.2 Instalación con Kubeadm
- ✓ Preparación de infraestructura
- ✓ Instalación de container runtime (containerd)
- ✓ Configuración de kubeadm, kubelet, kubectl
- ✓ Inicialización del control plane
- ✓ Unión de worker nodes

**Recursos:** `prepare-k8s/` - Scripts de instalación automatizada

### 🔄 En Progreso

#### 1.3 Configuración de Red y CNI
- 🔄 Conceptos CNI (Container Network Interface)
- 🔄 Instalación de plugins: Calico, Flannel, Weave
- 🔄 Pod CIDR y overlay networks
- 🔄 Service networking y kube-proxy

**Recursos:** `1.3-cni/` - Guías y laboratorios de CNI

### 📋 Pendiente

#### 1.4 Alta Disponibilidad y etcd
#### 1.5 TLS y Comunicaciones Seguras
#### 1.6 Helm y Kustomize
#### 1.7 CRDs y Operators
#### 1.8 Upgrade y Mantenimiento

## Estructura del Repositorio

```
cka/
├── README.md                    # Este archivo
├── prepare-k8s/                 # 1.2 - Scripts de instalación
│   ├── ubuntu.sh
│   ├── rockylinux.sh
│   ├── setup-flannel.sh
│   ├── cleanup.sh
│   └── README.md
└── 1.3-cni/                     # 1.3 - CNI y Networking
    ├── README.md                # Guía completa de CNI
    ├── flannel/
    ├── calico/
    └── weave/
```

## Exam Preparation

### Key Topics to Master
- **kubectl commands**: Resource management and troubleshooting
- **YAML manifests**: Writing and debugging configuration files
- **Cluster lifecycle**: Installation, upgrade, and maintenance
- **Application deployment**: From simple pods to complex applications
- **Security**: Authentication, authorization, and network policies

### Our Weekly Study Plan

We'll advance together through these topics as a group:

- **Week 1**: Cluster setup and basic concepts (collective environment setup)
- **Week 2**: Workloads and scheduling (shared practice scenarios)
- **Week 3**: Storage and networking (group troubleshooting sessions)
- **Week 4**: Security and advanced topics (peer review and discussions)
- **Week 5**: Practice exams and final preparation (mock exams as a team)

*This repository will grow with our progress - each member can contribute notes, solutions, and additional resources as we advance.*

## Essential Commands

### Cluster Management
```bash
# Get cluster information
kubectl cluster-info
kubectl get nodes
kubectl get componentstatuses

# Node management
kubectl describe node <node-name>
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets
```

### CNI Troubleshooting
```bash
# Ver configuración CNI actual
cat /etc/cni/net.d/*.conflist

# Ver binarios CNI disponibles
ls /opt/cni/bin/

# Verificar Pods de red
kubectl get pods -n kube-system -l k8s-app=<cni-name>

# Logs de CNI
kubectl logs -n kube-system -l k8s-app=calico-node
```

### Resource Management
```bash
# Deploy applications
kubectl create deployment <name> --image=<image>
kubectl scale deployment <name> --replicas=<count>
kubectl expose deployment <name> --port=<port> --target-port=<target-port>

# Troubleshoot
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
```

## Practice Scenarios

### Module 1.2 - Instalación
- ✓ Deploy a multi-node cluster with kubeadm
- ✓ Configure containerd as container runtime
- ✓ Join worker nodes to control plane

### Module 1.3 - CNI (En Progreso)
- 🔄 Install and configure Flannel
- 🔄 Install and configure Calico
- 🔄 Compare CNI performance
- 🔄 Implement Network Policies

## Additional Resources

### Official Documentation
- Kubernetes Documentation: kubernetes.io/docs
- CKA Exam Curriculum: kubernetes.io/certification/cka
- **Syllabus del Grupo:** https://cka.amxops.com

### Practice Tools
- Kubernetes Playground: killercoda.com
- Online Terminal: katacoda.com
- Local Clusters: minikube, kind, k3d

## Contributing to Our Study Repository

This is a living repository that grows with our collective knowledge:

### How to Contribute
- **Share solutions**: Add your solved exercises and approaches
- **Document findings**: Create notes on challenging topics
- **Add resources**: Share helpful links, tools, or references
- **Update progress**: Mark completed modules and add new practice scenarios
- **Help others**: Review and improve existing content

### Repository Structure
- Each member can create branches for their contributions
- We'll merge content regularly as we advance through topics
- Discussion threads for complex problems and alternative solutions

---

**Note**: This repository represents our collective journey toward CKA certification. Every contribution helps the entire group succeed.
