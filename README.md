# CKA Study Group - Certified Kubernetes Administrator Preparation

Repositorio colaborativo para la preparación del examen CKA. Avanzamos juntos siguiendo el [Syllabus Oficial CKA 2026](https://cka.amxops.com).

**Progreso Actual:** Módulo 1.3 - Configuración de Red y CNI

---

## Módulos

### ✅ [1.2 Instalación con Kubeadm](1.2-instalacion-kubeadm/)
Scripts automatizados para instalar clústeres Kubernetes con kubeadm.

**Contenido:**
- [ubuntu.sh](1.2-instalacion-kubeadm/ubuntu.sh) - Instalación en Ubuntu
- [rockylinux.sh](1.2-instalacion-kubeadm/rockylinux.sh) - Instalación en Rocky Linux
- [setup-flannel.sh](1.2-instalacion-kubeadm/setup-flannel.sh) - Instalación de Flannel CNI
- [cleanup.sh](1.2-instalacion-kubeadm/cleanup.sh) - Limpieza de componentes

---

### 🔄 [1.3 Configuración de Red y CNI](1.3-cni/)
Instalación y configuración de plugins CNI (Container Network Interface).

**Contenido:**
- [TEORIA.md](1.3-cni/TEORIA.md) - Fundamentos y arquitectura de CNI
- [LABS.md](1.3-cni/LABS.md) - 5 laboratorios prácticos
  - Lab 1: Verificar flujo CNI
  - Lab 2: Benchmark de rendimiento
  - Lab 3: Network Policies básicas
  - Lab 4: Troubleshooting CNI
  - Lab 5: Network Policies multi-tier

---

## Comandos Esenciales

### Cluster Management
```bash
kubectl cluster-info
kubectl get nodes
kubectl get componentstatuses
```

### CNI Troubleshooting
```bash
# Ver configuración CNI
cat /etc/cni/net.d/*.conflist

# Ver Pods de CNI
kubectl get pods -n kube-system

# Logs de CNI
kubectl logs -n kube-system -l k8s-app=calico-node
```

### Pod Management
```bash
kubectl run <name> --image=<image>
kubectl get pods -o wide
kubectl describe pod <name>
kubectl logs <name>
kubectl exec -it <name> -- /bin/bash
```

---

## Recursos

- [Syllabus del Grupo](https://cka.amxops.com)
- [Documentación Oficial Kubernetes](https://kubernetes.io/docs)
- [CKA Exam Curriculum](https://kubernetes.io/certification/cka)

---

## Contribuir

Este repositorio crece con nuestro progreso colectivo:

- Agrega soluciones y ejercicios resueltos
- Documenta hallazgos y notas
- Comparte recursos útiles
- Ayuda a otros miembros del grupo

---

*Este repositorio representa nuestro avance hacia la certificación CKA.*
