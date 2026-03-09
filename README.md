# CKA Study Group - Certified Kubernetes Administrator Preparation

Repositorio colaborativo para la preparación del examen CKA. Avanzamos juntos siguiendo el [Syllabus Oficial CKA 2026](https://cka.amxops.com).

📍 **Progreso Actual:** Módulo 1.3 - Configuración de Red y CNI

---

## 📚 Módulos

### ✅ 1.2 Instalación con Kubeadm
Scripts automatizados para instalar clústeres Kubernetes con kubeadm.

**Contenido:**
- Instalación en Ubuntu y Rocky Linux
- Configuración de containerd
- Inicialización de control plane
- Unión de worker nodes

📁 **Directorio:** `1.2-instalacion-kubeadm/`

---

### 🔄 1.3 Configuración de Red y CNI
Instalación y configuración de plugins CNI (Container Network Interface).

**Contenido:**
- Guía teórica completa de CNI
- Instalación de Flannel, Calico, Weave
- 5 laboratorios prácticos
- Network Policies

📁 **Directorio:** `1.3-cni/`

---

## 🚀 Comandos Esenciales

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

## 📖 Recursos

- [Syllabus del Grupo](https://cka.amxops.com)
- [Documentación Oficial Kubernetes](https://kubernetes.io/docs)
- [CKA Exam Curriculum](https://kubernetes.io/certification/cka)

---

## 🤝 Contribuir

Este repositorio crece con nuestro progreso colectivo:

- Agrega soluciones y ejercicios resueltos
- Documenta hallazgos y notas
- Comparte recursos útiles
- Ayuda a otros miembros del grupo

---

**Nota:** Este repositorio representa nuestro avance hacia la certificación CKA. Cada contribución ayuda al grupo completo.
