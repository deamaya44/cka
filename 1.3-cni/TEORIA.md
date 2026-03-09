# 1.3 Configuración de Red y CNI

Guías y laboratorios prácticos para instalar y configurar plugins CNI en Kubernetes.

## 📚 Contenido

### [LABS.md](LABS.md)
Laboratorios prácticos paso a paso:
1. Verificar flujo CNI completo
2. Comparar rendimiento entre CNIs
3. Network Policies básicas
4. Troubleshooting CNI
5. Network Policies multi-tier

### [TEORIA.md](TEORIA.md)
Guía teórica completa:
- Fundamentos de CNI
- Arquitectura y componentes
- Pod CIDR y Overlay Networks
- Comparativa detallada de plugins

## 🔧 CNIs Cubiertos

- **Flannel** - Overlay VXLAN simple
- **Calico** - L3 BGP con Network Policies avanzadas
- **Weave Net** - Mesh network con cifrado

## 🚀 Inicio Rápido

```bash
# Seguir laboratorios prácticos
cat LABS.md

# Consultar teoría cuando sea necesario
cat TEORIA.md
```

## 📚 Recursos

- [Documentación CNI oficial](https://www.cni.dev/)
- [Syllabus CKA - Módulo 1.3](https://cka.amxops.com)

---

**Parte del módulo 1.3 del Syllabus CKA 2026**
