# Operators

## Descripción

El directorio `operators` contiene la instalación y gestión de los operadores desplegados en la plataforma OpenShift mediante **Operator Lifecycle Manager (OLM)**.

Esta capa es responsable exclusivamente de la instalación de operadores y de sus dependencias asociadas. No debe incluir la configuración funcional de los servicios gestionados por dichos operadores.

La configuración específica de cada operador debe mantenerse en el directorio `cluster-custom-resources`.

---

## Objetivos

- Gestionar la instalación de operadores mediante GitOps.
- Mantener separadas la instalación y configuración de cada servicio.
- Garantizar una secuencia de despliegue consistente y reproducible.
- Facilitar las actualizaciones y el mantenimiento de operadores.
- Reducir dependencias entre componentes de la plataforma.

---

## Arquitectura

```text
Namespace
    │
    ▼
OperatorGroup
    │
    ▼
Subscription
    │
    ▼
ClusterServiceVersion (CSV)
    │
    ▼
CustomResourceDefinitions (CRDs)
    │
    ▼
Custom Resources
```

Este directorio gestiona únicamente las cuatro primeras capas.

Los Custom Resources son gestionados desde:

```text
cluster-custom-resources/
```

---

## Estructura

```text
operators/
├── apps
├── cluster-logging
├── loki-operator
├── lvms-operator
└── openshift-cluster-observability-operator
```

---

## apps

Contiene las aplicaciones ArgoCD responsables de desplegar los operadores definidos en este dominio.

Ejemplo:

```text
operators/
└── apps
    └── operators.yaml
```

La aplicación será creada automáticamente por la Root Application durante el proceso de bootstrap.

---

## cluster-logging

Instalación del operador OpenShift Logging.

Ejemplos de recursos:

```yaml
Namespace
OperatorGroup
Subscription
```

Responsabilidades:

- Instalación del operador de logging.
- Gestión del ciclo de vida del operador.
- Creación de CRDs relacionados con Cluster Logging.

---

## loki-operator

Instalación del operador Loki.

Ejemplos de recursos:

```yaml
Namespace
OperatorGroup
Subscription
```

Responsabilidades:

- Instalación del operador Loki.
- Gestión de CRDs LokiStack.
- Preparación del almacenamiento de logs.

---

## lvms-operator

Instalación del operador Logical Volume Manager Storage.

Ejemplos de recursos:

```yaml
Namespace
OperatorGroup
Subscription
```

Responsabilidades:

- Instalación del operador LVMS.
- Creación de los CRDs necesarios para LVMCluster.
- Gestión del almacenamiento local basado en LVM.

---

## openshift-cluster-observability-operator

Instalación del operador OpenShift Cluster Observability.

Ejemplos de recursos:

```yaml
Namespace
OperatorGroup
Subscription
```

Responsabilidades:

- Integración con OpenShift Monitoring.
- Exposición de métricas de infraestructura.
- Habilitación de funcionalidades avanzadas de observabilidad.

---

## Recursos Gestionados

Cada directorio de operador puede contener los siguientes recursos:

### Namespace

Define el namespace donde será instalado el operador.

Ejemplo:

```yaml
apiVersion: v1
kind: Namespace
```

---

### OperatorGroup

Define el ámbito de observación del operador.

Ejemplo:

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
```

---

### Subscription

Gestiona la instalación y actualización automática del operador.

Ejemplo:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
```

---

## Recursos NO Permitidos

No deben almacenarse en este directorio:

### Custom Resources

Incorrecto:

```text
operators/
└── lvms-operator
    ├── subscription.yaml
    └── lvmcluster.yaml
```

Correcto:

```text
operators/
└── lvms-operator
    ├── namespace.yaml
    ├── operatorgroup.yaml
    └── subscription.yaml
```

```text
cluster-custom-resources/
└── lvms-operator
    └── lvmcluster.yaml
```

---

### Recursos de Configuración

No incluir:

```text
StorageClasses
LVMCluster
LokiStack
ClusterLogging
ClusterLogForwarder
QuayRegistry
```

Estos recursos deben mantenerse en:

```text
cluster-custom-resources/
```

---

## Dependencias

Antes de desplegar esta capa deben existir:

### Bootstrap desplegado

```text
bootstrap
```

---

### Cluster Config desplegado

```text
cluster-config
```

---

### Policies desplegadas

```text
policies
```

Particularmente:

```text
RBAC
Groups
ClusterRoles
ClusterRoleBindings
```

---

## Sync Wave

Esta capa se despliega después de la configuración base y las políticas del clúster.

```yaml
argocd.argoproj.io/sync-wave: "30"
```

Orden:

```text
cluster-config
    │
    ▼
policies
    │
    ▼
operators
```

---

## Health Checks

La plataforma utiliza Health Checks globales configurados en ArgoCD para validar la instalación de operadores.

### Subscription

Estado Healthy cuando:

```text
status.installedCSV != nil
```

---

### ClusterServiceVersion (CSV)

Estado Healthy cuando:

```text
status.phase = Succeeded
```

Esto garantiza que:

- El operador ha sido instalado.
- Los CRDs han sido registrados.
- OLM ha completado la instalación.

---

## Verificaciones Operativas

### Estado de las Subscriptions

```bash
oc get subscriptions -A
```

---

### Estado de las CSV

```bash
oc get csv -A
```

Estado esperado:

```text
Succeeded
```

---

### Estado de los Pods de Operadores

```bash
oc get pods -A | grep operator
```

---

### Estado de la Aplicación ArgoCD

```bash
oc get application operators -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## Actualización de Operadores

Las actualizaciones son gestionadas por OLM mediante las Subscriptions definidas en Git.

Para actualizar un operador:

1. Modificar la Subscription.
2. Crear Pull Request.
3. Aprobar y fusionar cambios.
4. Permitir que ArgoCD sincronice la aplicación.

Verificar posteriormente:

```bash
oc get csv -A
```

---

## Troubleshooting

### Subscription en estado Pending

Verificar:

```bash
oc describe subscription <subscription>
```

---

### CSV en estado Failed

Verificar:

```bash
oc describe csv <csv-name>
```

Y revisar los eventos:

```bash
oc get events -A --sort-by=.metadata.creationTimestamp
```

---

### Operador sin Pods

Verificar:

```bash
oc get deployment -A
```

```bash
oc get pods -A
```

---

### CRD inexistente

Verificar:

```bash
oc get crd
```

Ejemplo:

```bash
oc get crd | grep lvm
```

Si el CRD no existe, revisar el estado de la CSV asociada.

---

## Recuperación

Durante una reconstrucción completa del clúster:

1. ArgoCD despliega la aplicación `operators`.
2. OLM instala los operadores definidos.
3. Los Health Checks validan Subscriptions y CSV.
4. Las siguientes capas podrán desplegarse automáticamente.

No deben aplicarse Custom Resources hasta que esta capa alcance el estado:

```text
Healthy
```

---

## Principios de Diseño

- Separación estricta entre instalación y configuración.
- Operadores gestionados únicamente mediante OLM.
- Gestión declarativa mediante GitOps.
- Integración con Health Checks globales de ArgoCD.
- Despliegue reproducible y auditable.
- Actualizaciones controladas mediante Pull Requests.
- Compatibilidad con despliegues Day-0 y procesos de recuperación ante desastres.
```**`**````
