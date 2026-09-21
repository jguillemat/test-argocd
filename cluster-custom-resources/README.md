# Cluster Custom Resources

## Descripción

El directorio `cluster-custom-resources` contiene los **Custom Resources (CRs)** asociados a los operadores desplegados en la plataforma OpenShift.

Estos recursos representan la configuración funcional de los servicios gestionados por operadores instalados previamente a través de OLM (Operator Lifecycle Manager).

Esta capa se despliega únicamente cuando:

- Los operadores han sido instalados correctamente.
- Los CSV (ClusterServiceVersion) se encuentran en estado `Succeeded`.
- Los CRDs necesarios están disponibles en el clúster.
- Los operadores han alcanzado un estado saludable.

---

## Objetivos

- Separar la instalación de operadores de su configuración.
- Evitar dependencias entre `Subscription` y `Custom Resources`.
- Facilitar la gestión independiente de los CRs.
- Mejorar la trazabilidad y mantenimiento de la configuración de plataforma.
- Reducir errores durante despliegues Day-0 y reconstrucciones del clúster.

---

## Arquitectura

```text
Operators
    │
    ▼
OperatorGroup
    │
    ▼
Subscription
    │
    ▼
CSV
    │
    ▼
CRDs disponibles
    │
    ▼
Cluster Custom Resources
```

---

## Estructura

```text
cluster-custom-resources/
├── apps
├── lvms-operator
└── quay-ha
```

### apps

Contiene las aplicaciones ArgoCD encargadas de desplegar los recursos definidos en este dominio.

Ejemplo:

```text
cluster-custom-resources/
└── apps
    └── cluster-custom-resources.yaml
```

---

### lvms-operator

Configuración asociada al operador Logical Volume Manager Storage.

Ejemplos:

```text
lvms-operator/
└── lvmcluster.yaml
```

Recursos gestionados:

```yaml
apiVersion: lvm.topolvm.io/v1alpha1
kind: LVMCluster
```

---

### quay-ha

Configuración asociada a una instalación de Red Hat Quay en alta disponibilidad.

Ejemplos:

```text
quay-ha/
├── quayregistry.yaml
├── object-storage.yaml
└── route.yaml
```

Recursos gestionados:

```yaml
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
```

---

## Sync Wave

Esta capa se despliega después de:

- cluster-config
- policies
- operators
- platform
- storage

Configuración utilizada:

```yaml
argocd.argoproj.io/sync-wave: "70"
```

---

## Dependencias

Antes de desplegar cualquier recurso contenido en este directorio deben cumplirse las siguientes condiciones:

### Operadores instalados

Los operadores correspondientes deben encontrarse instalados mediante OLM.

Ejemplos:

```text
LVMS Operator
Quay Operator
```

---

### CSV en estado Succeeded

Verificación:

```bash
oc get csv -A
```

Ejemplo esperado:

```text
Succeeded
```

---

### CRDs disponibles

Verificación:

```bash
oc get crd
```

Ejemplos:

```text
lvmclusters.lvm.topolvm.io
quayregistries.quay.redhat.com
```

---

### Aplicación Operators Healthy

La aplicación ArgoCD responsable de los operadores debe encontrarse en:

```text
Healthy
Synced
```

---

## Health Checks

Los principales recursos de este directorio disponen de validaciones de estado personalizadas mediante Lua en ArgoCD.

### LVMCluster

Estado esperado:

```text
Ready=True
```

La aplicación no se considerará Healthy hasta que el clúster LVM esté completamente operativo.

---

### QuayRegistry

Estado esperado:

```text
Available=True
```

o equivalente según la versión del operador.

La aplicación no se marcará como Healthy hasta que la instancia de Quay sea funcional.

---

## Buenas Prácticas

### No instalar operadores en este directorio

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

Incorrecto:

```text
cluster-custom-resources/
├── subscription.yaml
└── lvmcluster.yaml
```

---

### Un directorio por operador

Recomendado:

```text
cluster-custom-resources/
├── lvms-operator
├── quay-ha
├── loki
├── cluster-logging
└── odf
```

Esto facilita:

- Mantenimiento.
- Versionado.
- Troubleshooting.
- Escalabilidad.

---

### Evitar recursos compartidos

Cada directorio debe contener únicamente CRs relacionados con un único operador o servicio.

Evitar:

```text
cluster-custom-resources/
└── misc
```

---

### Mantener consistencia entre operadores y CRs

Se recomienda mantener una estructura similar entre los directorios:

```text
operators/
└── lvms-operator
```

```text
cluster-custom-resources/
└── lvms-operator
```

Esto facilita la identificación de dependencias.

---

## Despliegue

Los recursos de este directorio se despliegan automáticamente mediante ArgoCD.

Verificación:

```bash
oc get application cluster-custom-resources -n openshift-gitops
```

Estado esperado:

```text
Sync: Synced
Health: Healthy
```

---

## Troubleshooting

### Error: No matches for kind

Ejemplo:

```text
no matches for kind "LVMCluster"
```

Causa probable:

- El CRD todavía no existe.
- El operador no se ha instalado correctamente.

Verificar:

```bash
oc get crd | grep lvm
```

---

### Error: Failed calling webhook

Ejemplo:

```text
failed calling webhook
```

Causa probable:

- El operador no está completamente operativo.
- El webhook todavía no responde.

Verificar:

```bash
oc get pods -A
```

---

### Aplicación en estado Progressing

Verificar:

```bash
oc describe application cluster-custom-resources -n openshift-gitops
```

y:

```bash
oc get events -A --sort-by=.metadata.creationTimestamp
```

---

## Principios de Diseño

- Separación estricta entre operadores y configuración.
- Despliegue basado en dependencias.
- Recursos declarativos gestionados mediante GitOps.
- Compatibilidad con despliegues Day-0.
- Compatibilidad con reconstrucciones completas de plataforma.
- Integración con Health Checks personalizados de ArgoCD.
- Escalabilidad para futuros operadores y servicios de infraestructura.
