# Platform

## Descripción

El directorio `platform` contiene la configuración de los servicios nativos de OpenShift necesarios para el correcto funcionamiento de la plataforma.

Esta capa agrupa recursos que modifican el comportamiento operativo del clúster y que forman parte de la configuración base de OpenShift.

Los componentes definidos en este directorio suelen afectar a:

- Networking
- Ingress
- DNS
- Registro de imágenes
- Configuración de nodos
- Rendimiento del clúster
- Configuración del sistema operativo de los nodos

La configuración almacenada en esta capa debe considerarse parte de la infraestructura base del clúster y gestionarse exclusivamente mediante GitOps.

---

## Objetivos

- Centralizar la configuración de servicios nativos de OpenShift.
- Gestionar de forma declarativa la infraestructura del clúster.
- Mantener la trazabilidad de todos los cambios de configuración.
- Reducir configuraciones manuales realizadas desde la consola.
- Garantizar despliegues consistentes y reproducibles.

---

## Arquitectura

```text
OpenShift Cluster
        │
        ▼
Platform Configuration
        │
 ┌──────┼─────────┬─────────┬───────────┐
 ▼      ▼         ▼         ▼           ▼
DNS   Ingress   Registry   Nodes      Performance
```

---

## Estructura

```text
platform/
├── apps
├── dns-operator
├── image-registry
├── ingress
│   └── default
├── kubeletconfig
├── machineconfig
├── machineconfigpool
├── proxy
└── tuned
```

---

## apps

Contiene las aplicaciones ArgoCD responsables de desplegar los recursos definidos en esta capa.

Ejemplo:

```text
platform/
└── apps
    └── platform.yaml
```

La aplicación será creada automáticamente desde el Bootstrap Application.

---

## dns-operator

Contiene la configuración del operador DNS de OpenShift.

Ejemplos:

```yaml
DNS
```

Casos habituales:

- Forwarders DNS
- DNS internos corporativos
- Resolución híbrida
- Split DNS

---

## image-registry

Configuración del registro interno de OpenShift.

Ejemplos:

```yaml
Config
```

Casos habituales:

- Configuración de almacenamiento
- Exposición externa
- Réplicas
- Configuración de rutas
- Integración con storage backend

---

## ingress

Contiene la configuración de los controladores de Ingress.

Ejemplo:

```text
ingress/
└── default
```

Recursos habituales:

```yaml
IngressController
```

Casos de uso:

- Certificados TLS
- Wildcard Domains
- Réplicas de routers
- Afinidad
- Configuración de balanceo

---

## kubeletconfig

Configuración de los servicios kubelet de los nodos.

Recursos habituales:

```yaml
KubeletConfig
```

Ejemplos:

- Límites de recursos
- Configuración de logs
- Garbage Collection
- Tuning del kubelet

---

## machineconfig

Configuración de bajo nivel aplicada a los nodos del clúster.

Recursos habituales:

```yaml
MachineConfig
```

Ejemplos:

- Ficheros de configuración
- Servicios systemd
- Configuración del sistema operativo
- Ajustes de kernel

---

## machineconfigpool

Configuración de los MachineConfigPools.

Recursos habituales:

```yaml
MachineConfigPool
```

Ejemplos:

- Pools de nodos personalizados
- Configuración específica para workers
- Configuración específica para infra nodes
- Configuración específica para storage nodes

---

## proxy

Configuración global del proxy del clúster.

Recursos habituales:

```yaml
Proxy
```

Casos habituales:

- HTTP Proxy
- HTTPS Proxy
- No Proxy
- Acceso a registros externos
- Acceso a repositorios Git

---

## tuned

Perfiles de optimización y rendimiento.

Recursos habituales:

```yaml
Tuned
```

Ejemplos:

- Optimización de cargas de trabajo
- Ajustes de CPU
- Ajustes de memoria
- Configuración NUMA
- Ajustes específicos de infraestructura

---

## Dependencias

Antes de desplegar esta capa deben existir:

### Cluster Config

```text
cluster-config
```

---

### Policies

```text
policies
```

---

### Operators

```text
operators
```

Todos los operadores requeridos por la plataforma deben encontrarse instalados correctamente.

---

## Sync Wave

Esta capa se despliega después de la instalación y validación de operadores.

```yaml
argocd.argoproj.io/sync-wave: "50"
```

Secuencia:

```text
cluster-config
    │
policies
    │
operators
    │
operators-health
    │
platform
```

---

## Consideraciones Importantes

### MachineConfig

Los cambios en recursos `MachineConfig` suelen provocar:

```text
Node Drain
Node Reboot
Node Update
```

Antes de aplicar cambios se recomienda verificar:

```bash
oc get mcp
```

---

### MachineConfigPool

Un cambio incorrecto puede dejar nodos en estado:

```text
Updating
Degraded
```

Verificar siempre:

```bash
oc get mcp
```

---

### Proxy

Las modificaciones en el recurso:

```yaml
kind: Proxy
```

pueden afectar a:

- Operadores
- Pull de imágenes
- Integraciones externas
- Acceso a Git
- Acceso a registries

Validar cuidadosamente antes de aplicar cambios.

---

### Ingress

Los cambios sobre:

```yaml
kind: IngressController
```

pueden provocar:

- Recreación de routers
- Cambios en certificados
- Cambios DNS
- Breves interrupciones del tráfico

---

## Buenas Prácticas

### Un directorio por servicio

Correcto:

```text
platform/
├── dns-operator
├── image-registry
├── ingress
├── kubeletconfig
├── machineconfig
├── machineconfigpool
├── proxy
└── tuned
```

---

### Mantener configuraciones independientes

Evitar:

```text
platform/
└── misc
```

Separar siempre los recursos por dominio funcional.

---

### Gestionar cambios mediante Pull Requests

Toda modificación de:

```text
MachineConfig
Proxy
IngressController
DNS
```

debe realizarse mediante revisión y aprobación previa.

---

### Validar MachineConfigPools

Después de cualquier cambio relacionado con nodos:

```bash
oc get mcp
```

Estado esperado:

```text
UPDATED=True
UPDATING=False
DEGRADED=False
```

---

## Verificaciones Operativas

### Estado de MachineConfigPools

```bash
oc get mcp
```

---

### Estado de MachineConfigs

```bash
oc get machineconfig
```

---

### Estado de IngressControllers

```bash
oc get ingresscontroller -n openshift-ingress-operator
```

---

### Estado del Proxy

```bash
oc get proxy cluster -o yaml
```

---

### Estado DNS

```bash
oc get dns.operator/default -o yaml
```

---

### Estado del Registro

```bash
oc get configs.imageregistry.operator.openshift.io cluster -o yaml
```

---

### Estado de la Aplicación ArgoCD

```bash
oc get application platform -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## Troubleshooting

### MachineConfigPool Updating indefinidamente

Verificar:

```bash
oc describe mcp
```

y:

```bash
oc get nodes
```

---

### MachineConfigPool Degraded

Verificar:

```bash
oc describe mcp
```

```bash
oc get machineconfig
```

---

### Problemas de resolución DNS

Verificar:

```bash
oc get dns.operator/default -o yaml
```

y:

```bash
oc debug node/<node>
```

---

### Problemas de acceso a Internet

Verificar:

```bash
oc get proxy cluster -o yaml
```

Comprobar:

```text
httpProxy
httpsProxy
noProxy
```

---

### Problemas en los Routers

Verificar:

```bash
oc get pods -n openshift-ingress
```

```bash
oc get ingresscontroller -n openshift-ingress-operator
```

---

## Recuperación

Durante la reconstrucción del clúster esta capa será desplegada automáticamente por ArgoCD después de completar:

```text
cluster-config
policies
operators
operators-health
```

No se recomienda aplicar manualmente recursos de esta carpeta fuera del flujo GitOps.

---

## Principios de Diseño

- Configuración declarativa de OpenShift.
- Gestión centralizada mediante GitOps.
- Separación por dominios funcionales.
- Trazabilidad completa de cambios.
- Despliegue reproducible y auditable.
- Compatibilidad con recuperación ante desastres.
- Orientación a operación y mantenimiento de plataformas OpenShift empresariales.
