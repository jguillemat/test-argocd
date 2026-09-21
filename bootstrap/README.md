# Bootstrap

## Descripción

El directorio `bootstrap` contiene la configuración mínima necesaria para iniciar la plataforma GitOps basada en ArgoCD.

Su objetivo es desplegar una única **Root Application** que actuará como punto de entrada del modelo **App of Apps**, encargándose de crear y gestionar el resto de aplicaciones del clúster.

Una vez desplegada la Root Application, toda la configuración de la plataforma será gestionada automáticamente desde Git.

---

## Arquitectura

```text
bootstrap
    │
    ▼
Root Application
    │
    ├── cluster-config
    ├── policies
    ├── operators
    ├── platform
    ├── storage
    ├── cluster-custom-resources
    └── observability
```

---

## Estructura

```text
bootstrap/
└── argocd
    └── applications
        ├── 10-cluster-config.yaml
        ├── 20-policies.yaml
        ├── 30-operators.yaml
        ├── 50-platform.yaml
        ├── 60-storage.yaml
        ├── 70-cluster-custom-resources.yaml
        └── 80-observability.yaml
```

---

## Componentes

### Root Application

La Root Application es la única aplicación que debe aplicarse manualmente en el clúster.

Responsabilidades:

- Inicializar la jerarquía GitOps.
- Crear las aplicaciones hijas.
- Gestionar el orden de despliegue mediante Sync Waves.
- Garantizar la reconciliación continua de toda la plataforma.

---

### Aplicaciones Hijas

Cada directorio funcional del repositorio dispone de una aplicación ArgoCD independiente.

Ejemplos:

- cluster-config
- policies
- operators
- platform
- storage
- cluster-custom-resources
- observability

Estas aplicaciones son creadas automáticamente por la Root Application.

---

## Sync Waves

La plataforma utiliza Sync Waves para garantizar el despliegue ordenado de los distintos componentes.

| Wave | Aplicación | Descripción |
|--------|------------|-------------|
| 10 | cluster-config | Configuración base del clúster |
| 20 | policies | RBAC, Network Policies y EgressIP |
| 30 | operators | Instalación de operadores mediante OLM |
| 50 | platform | Configuración de OpenShift |
| 60 | storage | Configuración de almacenamiento |
| 70 | cluster-custom-resources | Custom Resources de operadores |
| 80 | observability | Monitoring, Logging y Alerting |

---

## Requisitos Previos

Antes de desplegar el bootstrap deben cumplirse los siguientes requisitos:

### OpenShift GitOps instalado

Verificar:

```bash
oc get csv -n openshift-operators | grep gitops
```

### Namespace de ArgoCD disponible

```bash
oc get ns openshift-gitops
```

### Acceso al repositorio Git

El repositorio deberá estar accesible desde ArgoCD y contar con las credenciales necesarias.

Verificar:

```bash
oc get secrets -n openshift-gitops
```

---

## Despliegue Inicial

Aplicar únicamente la Root Application:

```bash
oc apply -f app-cluster-root.yaml
```

o alternativamente:

```bash
oc create -f app-cluster-root.yaml
```

Una vez creada:

```bash
oc get applications -n openshift-gitops
```

La Root Application generará automáticamente el resto de aplicaciones definidas bajo:

```text
bootstrap/argocd/applications
```

---

## Recuperación de la Plataforma

Uno de los principales objetivos del bootstrap es facilitar la reconstrucción completa del clúster.

Ante una pérdida del clúster o una reinstalación de OpenShift basta con:

1. Instalar OpenShift GitOps.
2. Configurar el acceso al repositorio Git.
3. Aplicar la Root Application.

```bash
oc apply -f app-cluster-root.yaml
```

ArgoCD reconciliará automáticamente toda la configuración definida en Git.

---

## Convenciones

### Una aplicación por dominio funcional

Ejemplo:

```text
cluster-config
policies
operators
platform
storage
cluster-custom-resources
observability
```

### Gestión exclusiva desde Git

Toda modificación deberá realizarse mediante Pull Request.

No se recomienda realizar cambios manuales sobre recursos gestionados por ArgoCD.

### Recursos declarativos

Todos los objetos desplegados por ArgoCD deben mantenerse en formato declarativo dentro del repositorio Git y ser reproducibles de manera consistente en cualquier entorno.

---

## Principios de Diseño

- Git como fuente única de verdad.
- Despliegue declarativo.
- Reconstrucción completa del clúster mediante bootstrap.
- Separación entre operadores y Custom Resources.
- Gestión ordenada mediante Sync Waves.
- Escalabilidad para incorporar nuevos dominios de plataforma en el futuro.
