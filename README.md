# OpenShift GitOps Platform Repository

Repositorio GitOps para la gestión declarativa de la plataforma OpenShift mediante ArgoCD utilizando el patrón **Apps of Apps**.

## Objetivos

- Gestionar toda la configuración de OpenShift desde Git.
- Separar claramente infraestructura, operadores, configuración de plataforma y observabilidad.
- Garantizar el despliegue ordenado mediante ArgoCD Sync Waves.
- Facilitar la reconstrucción completa del clúster a partir de un único Bootstrap Application.
- Mantener una estructura escalable y fácilmente extensible para futuros servicios.

---

# Arquitectura

```text
Bootstrap Application
        │
        ▼
┌─────────────────────┐
│   cluster-config    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│      policies       │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│      operators      │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  operators-health   │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│      platform       │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│      storage        │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ cluster-custom-res. │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│    observability    │
└─────────────────────┘
```

---

# Estructura del Repositorio

```text
.
├── bootstrap
│   ├── app-cluster-root.yaml
│   └── argocd
│       └── applications
│
├── cluster-config
│   └── apps
│
├── cluster-custom-resources
│   ├── apps
│   ├── lvms-operator
│   └── quay-ha
│
├── observability
│   ├── alerts
│   ├── apps
│   ├── dashboards
│   ├── logging
│   └── monitoring
│
├── operators
│   ├── apps
│   ├── cluster-logging
│   ├── loki-operator
│   ├── lvms-operator
│   └── openshift-cluster-observability-operator
│
├── operators-health
│   ├── apps
│   └── lvms-operator
│
├── platform
│   ├── apps
│   ├── dns-operator
│   ├── image-registry
│   ├── ingress
│   │   └── default
│   ├── kubeletconfig
│   ├── machineconfig
│   ├── machineconfigpool
│   ├── proxy
│   └── tuned
│
├── policies
│   ├── apps
│   ├── egressip
│   ├── networkpolicies
│   └── rbac
│       ├── cluster-groups
│       ├── cluster-rolebindings
│       └── cluster-roles
│
└── storage
    └── apps
```

---

# Descripción de Componentes

## bootstrap

Contiene la aplicación raíz de ArgoCD (Root Application) y la definición de las aplicaciones hijas que conforman la plataforma.

Responsabilidades:

- Bootstrap inicial del clúster.
- Gestión del modelo App of Apps.
- Orquestación mediante Sync Waves.

---

## cluster-config

Configuración base requerida antes de desplegar el resto de componentes.

Ejemplos:

- Namespaces
- Secrets de GitOps
- Pull Secrets
- Configuración global inicial

---

## policies

Configuración relacionada con seguridad, acceso y red.

Incluye:

- ClusterRoles
- ClusterRoleBindings
- Groups
- NetworkPolicies
- EgressIP

---

## operators

Instalación de operadores mediante OLM.

Incluye únicamente:

- Namespace
- OperatorGroup
- Subscription

No debe contener Custom Resources.

---

## operators-health

Validación funcional de operadores instalados.

Su objetivo es verificar que los operadores se encuentran completamente desplegados y disponibles antes de continuar con las siguientes fases.

Ejemplos:

- Deployments en estado Available
- Validación de CSV instaladas
- Comprobación de Pods Ready

---

## platform

Configuración nativa de OpenShift.

Incluye:

- Ingress Controllers
- Proxy
- DNS
- Image Registry
- MachineConfig
- MachineConfigPool
- KubeletConfig
- Tuned Profiles

---

## storage

Recursos relacionados con el almacenamiento de la plataforma.

Ejemplos futuros:

- StorageClasses
- VolumeSnapshotClasses
- ODF
- LVMS

---

## cluster-custom-resources

Custom Resources dependientes de operadores previamente desplegados.

Ejemplos:

- LVMCluster
- QuayRegistry

---

## observability

Componentes relacionados con monitorización, logging y visibilidad.

Incluye:

- Monitoring
- Logging
- Dashboards
- Alerting

---

# Sync Waves

La plataforma utiliza Sync Waves para garantizar el despliegue correcto de dependencias entre componentes.

| Wave | Aplicación | Descripción |
|--------|------------|-------------|
| 0 | bootstrap | Aplicación raíz (App of Apps) |
| 10 | cluster-config | Configuración base del clúster |
| 20 | policies | RBAC, Network Policies y EgressIP |
| 30 | operators | Instalación de operadores OLM |
| 40 | operators-health | Validación de operadores desplegados |
| 50 | platform | Configuración de OpenShift |
| 60 | storage | Configuración de almacenamiento |
| 70 | cluster-custom-resources | Custom Resources de los operadores |
| 80 | observability | Logging, Monitoring, Alerting y Dashboards |

---

# Principios de Diseño

## Separación de Operadores y CRs

Los operadores y sus recursos personalizados se gestionan en aplicaciones independientes.

### Correcto

```text
operators/
└── lvms-operator
    ├── namespace.yaml
    ├── operatorgroup.yaml
    └── subscription.yaml

cluster-custom-resources/
└── lvms-operator
    └── lvmcluster.yaml
```

### Incorrecto

```text
operators/
└── lvms-operator
    ├── subscription.yaml
    └── lvmcluster.yaml
```

---

## Health First

Antes de desplegar Custom Resources, la plataforma verifica que los operadores correspondientes estén completamente operativos.

El objetivo es evitar errores tales como:

```text
CRD not found
```

```text
failed calling webhook
```

```text
no matches for kind
```

---

## GitOps Declarativo

Todo cambio sobre la plataforma debe realizarse mediante Pull Request.

No se deben aplicar cambios manuales directamente sobre el clúster salvo situaciones excepcionales de emergencia.

---

# Bootstrap Inicial

Una vez desplegado OpenShift GitOps, la plataforma puede iniciarse aplicando únicamente la aplicación raíz:

```bash
oc apply -f bootstrap/app-cluster-root.yaml
```

A partir de ese momento ArgoCD sincronizará automáticamente el resto de componentes siguiendo el orden definido por las Sync Waves.

---

# Convenciones

## Estructura por componente

```text
<dominio>/
├── apps
└── <componente>
```

Ejemplo:

```text
operators/
├── apps
└── loki-operator
```

---

## Nomenclatura

Aplicaciones ArgoCD:

```text
cluster-config
policies
operators
operators-health
platform
storage
cluster-custom-resources
observability
```

Directorios:

```text
lower-case
```

Recursos:

```text
<tipo-recurso>-<nombre-recurso>.yaml
```

Ejemplo:

```text
subscription-loki.yaml
operatorgroup-lvms.yaml
quayregistry-myquay.yaml
```

