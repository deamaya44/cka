# 1.3 Configuración de Red y CNI

Instalación y configuración de plugins CNI en Kubernetes.

## Contenido

**[TEORIA.md](TEORIA.md)**  
Fundamentos de CNI, arquitectura de red, comparativa de plugins y casos de uso.

**[LABS.md](LABS.md)**  
Laboratorios prácticos: instalación, troubleshooting, network policies y benchmarks.

## Plugins Cubiertos

- **Flannel** - Overlay VXLAN, ideal para desarrollo
- **Calico** - BGP routing, network policies avanzadas
- **Weave Net** - Mesh network con cifrado automático

## Quick Start

```bash
# Revisar fundamentos
cat TEORIA.md

# Ejecutar laboratorios
cat LABS.md
```

## Referencias

- [CNI Specification](https://www.cni.dev/)
- [Syllabus CKA - Módulo 1.3](https://cka.amxops.com)

---

*Módulo 1.3 del Syllabus CKA 2026*
