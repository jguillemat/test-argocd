# Operators Health

## Descripción

El directorio `operators-health` contiene los recursos utilizados para validar que los operadores instalados mediante OLM se encuentran completamente operativos antes de continuar con el despliegue de recursos dependientes.

Aunque OpenShift GitOps y ArgoCD pueden validar el estado de las `Subscription` y las `ClusterServiceVersion (CSV)`, algunos operadores pueden requerir tiempo adicional para:

- Registrar CRDs.
- Habilitar webhooks.
- Arrancar controladores internos.
- Inicializar APIs.
- Crear servicios dependientes.

Esta capa proporciona un mecanismo adicional para verificar que un operador está realmente preparado para gestionar sus Custom Resources.

---

## Objetivos

- Validar la disponibilidad real de los operadores.
- Evitar errores relacionados con CRDs o webhooks no disponibles.
- Proporcionar una capa de control adicional entre la instalación de operadores y el despliegue de sus Custom Resources.
- Mejorar la fiabilidad de despliegues Day-0 y procesos de recuperación.

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
ClusterServiceVersion
    │
    ▼
Operator Deployment
    │
    ▼
Operators Health
    │
    ▼
Custom Resources
```

---

## Estructura

```text
operators-health/
├── apps
└── lvms-operator
```

---

## apps

Contiene las aplicaciones ArgoCD encargadas de gestionar las validaciones de salud definidas en este dominio.

Ejemplo:

```text
operators-health/
└── apps
    └── operators-health.yaml
```

---

## lvms-operator

Contiene los recursos utilizados para verificar que el operador LVMS se encuentra completamente operativo.

Ejemplo:

```text
lvms-operator/
└── deployment.yaml
```

Contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lvms-operator
  namespace: openshift-storage
```

ArgoCD monitorizará el estado del Deployment existente en el clúster y utilizará su estado para determinar la salud de la aplicación.

---

## Casos de Uso

### Validación de Deployments

Verifica que:

```text
Replicas
ReadyReplicas
AvailableReplicas
```

coinciden con el estado esperado.

Estado esperado:

```text
Available=True
ReadyReplicas=Replicas
```

---

### Validación de Pods

Permite asegurar que:

```text
Pods Running
Pods Ready
```

antes de desplegar recursos dependientes.

---

### Validación de Webhooks

Especialmente útil en operadores que registran:

```text
MutatingWebhookConfiguration
ValidatingWebhookConfiguration
```

ya que una CSV puede encontrarse en estado `Succeeded` antes de que los webhooks estén completamente operativos.

---

## ¿Es necesaria esta capa?

No siempre.

Si ArgoCD dispone de Health Checks globales correctamente configurados para:

```text
Subscription
ClusterServiceVersion
```

y los operadores son relativamente simples, esta capa puede resultar innecesaria.

Ejemplos habituales:

```text
Loki Operator
Cluster Logging Operator
OpenShift Cluster Observability Operator
```

En estos casos, la validación de la CSV suele ser suficiente.

---

## Cuándo utilizar Operators Health

Esta capa es recomendable cuando un operador:

- Utiliza webhooks.
- Registra APIs adicionales.
- Requiere inicializaciones complejas.
- Presenta tiempos de arranque elevados.
- Gestiona servicios críticos.

Ejemplos típicos:

```text
ODF
ACM
RamenDR
Submariner
Quay
```

---

## Dependencias

Antes de desplegar esta capa deben cumplirse las siguientes condiciones:

### Operators Healthy

La aplicación `operators` debe encontrarse en estado:

```text
Healthy
Synced
```

---

### CSV instaladas

Verificación:

```bash
oc get csv -A
```

Resultado esperado:

```text
Succeeded
```

---

### Deployments disponibles

Verificación:

```bash
oc get deployment -A
```

Resultado esperado:

```text
AVAILABLE > 0
```

---

## Sync Wave

Esta capa se despliega inmediatamente después de la instalación de operadores.

```yaml
argocd.argoproj.io/sync-wave: "40"
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
    │
storage
    │
cluster-custom-resources
```

---

## Relación con Health Checks Globales

La plataforma utiliza Health Checks globales para:

### Subscription

Estado Healthy cuando:

```text
status.installedCSV != nil
```

### CSV

Estado Healthy cuando:

```text
status.phase == Succeeded
```

La capa `operators-health` proporciona una validación adicional basada en recursos realmente ejecutándose dentro del clúster.

---

## Buenas Prácticas

### Un directorio por operador

Correcto:

```text
operators-health/
├── lvms-operator
├── quay-operator
├── acm
└── odf
```

---

### Mantener alineación con operators

Ejemplo:

```text
operators/
└── lvms-operator
```

```text
operators-health/
└── lvms-operator
```

Esto facilita la trazabilidad y el troubleshooting.

---

### Utilizar únicamente recursos observables

Recomendado:

```text
Deployment
StatefulSet
DaemonSet
```

Evitar:

```text
ConfigMaps
Secrets
```

ya que no aportan información sobre el estado operativo del operador.

---

## Verificaciones Operativas

### Estado de la aplicación

```bash
oc get application operators-health -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

### Estado del operador LVMS

```bash
oc get deployment -n openshift-storage
```

```bash
oc describe deployment lvms-operator \
  -n openshift-storage
```

---

### Estado de los Pods

```bash
oc get pods -n openshift-storage
```

Verificar:

```text
READY 1/1
STATUS Running
```

---

## Troubleshooting

### Aplicación en estado Progressing

Verificar:

```bash
oc describe application operators-health \
  -n openshift-gitops
```

---

### Deployment no disponible

Verificar:

```bash
oc get deployment -A
```

```bash
oc describe deployment <deployment>
```

---

### Pods en CrashLoopBackOff

Verificar:

```bash
oc get pods -A
```

```bash
oc logs <pod>
```

---

### CSV Healthy pero operador no operativo

Este es precisamente el escenario que justifica esta capa.

Puede ocurrir cuando:

- Los webhooks todavía no están disponibles.
- Las APIs aún no se han registrado completamente.
- Los controladores no han finalizado la inicialización.

En estos casos, `operators-health` evita que los recursos dependientes se desplieguen prematuramente.

---

## Futuro de esta Carpeta

Actualmente se utiliza para:

```text
lvms-operator
```

Sin embargo, puede ampliarse para validar otros operadores críticos:

```text
acm
odf
quay
ramendr
submariner
```

según evolucionen los servicios desplegados en la plataforma.

---

## Principios de Diseño

- Validación basada en el estado real del operador.
- Complemento a los Health Checks de Subscription y CSV.
- Despliegue seguro de recursos dependientes.
- Reducción de errores relacionados con CRDs y webhooks.
- Gestión declarativa mediante GitOps.
- Compatibilidad con despliegues Day-0 y recuperación de plataforma.
