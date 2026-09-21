# Storage

## Descripción

El directorio `storage` contiene la configuración relacionada con los servicios de almacenamiento utilizados por la plataforma OpenShift.

Esta capa es responsable de gestionar los recursos que proporcionan capacidades de almacenamiento persistente a la infraestructura, operadores y aplicaciones desplegadas en el clúster.

Su objetivo es abstraer la configuración de almacenamiento del resto de componentes de la plataforma y garantizar que todos los servicios dependientes dispongan de los recursos necesarios para operar correctamente.

---

## Objetivos

- Gestionar la configuración de almacenamiento mediante GitOps.
- Centralizar la definición de recursos de almacenamiento.
- Facilitar la gestión del ciclo de vida de los servicios de almacenamiento.
- Garantizar una capa común para operadores y aplicaciones.
- Proporcionar configuraciones reproducibles y auditables.

---

## Arquitectura

```text
Storage
   │
   ├── Storage Classes
   │
   ├── Snapshot Classes
   │
   ├── Local Storage
   │
   ├── Dynamic Provisioning
   │
   └── Persistent Storage Services
```

---

## Estructura

```text
storage/
└── apps
```

Actualmente esta capa actúa como punto de entrada para todos los servicios relacionados con almacenamiento.

A medida que la plataforma evolucione podrán incorporarse subdirectorios específicos para diferentes tecnologías o plataformas de almacenamiento.

Ejemplo:

```text
storage/
├── apps
├── lvms
├── storageclasses
├── volumesnapshotclasses
├── odf
└── noobaa
```

---

## apps

Contiene las aplicaciones ArgoCD responsables del despliegue de los recursos relacionados con almacenamiento.

Ejemplo:

```text
storage/
└── apps
    └── storage.yaml
```

La aplicación será creada automáticamente durante el proceso de bootstrap.

---

## Alcance

Esta capa puede ser utilizada para desplegar recursos como:

### StorageClass

Define los mecanismos de provisión de almacenamiento disponibles en el clúster.

Ejemplo:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
```

Casos habituales:

```text
lvms-vg1
ocs-storagecluster-ceph-rbd
ocs-storagecluster-cephfs
```

---

### VolumeSnapshotClass

Permite la creación de snapshots consistentes a nivel de almacenamiento.

Ejemplo:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
```

Casos habituales:

```text
CSI Snapshots
Backup Platforms
Disaster Recovery
```

---

### PersistentVolume

Recursos de almacenamiento físico o estático.

Ejemplo:

```yaml
apiVersion: v1
kind: PersistentVolume
```

---

### Servicios de almacenamiento

Dependiendo de la evolución de la plataforma, esta capa puede incluir configuraciones para:

```text
LVMS
ODF
NooBaa
Ceph
NFS
Local Storage
```

---

## Dependencias

Antes de desplegar esta capa deben existir:

### Cluster Config

```text
cluster-config
```

### Policies

```text
policies
```

### Operators

```text
operators
```

### Platform

```text
platform
```

En caso de utilizar almacenamiento gestionado por operadores, estos deberán encontrarse completamente instalados antes de desplegar sus recursos asociados.

---

## Sync Wave

La capa de almacenamiento se despliega después de la configuración base de OpenShift y antes de los Custom Resources dependientes.

```yaml
argocd.argoproj.io/sync-wave: "60"
```

Secuencia de despliegue:

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

## Relación con Cluster Custom Resources

La capa `storage` debe contener la configuración de los servicios de almacenamiento.

Los recursos específicos gestionados por operadores deben mantenerse en:

```text
cluster-custom-resources/
```

Ejemplo:

### Correcto

```text
storage/
└── storageclasses
```

```text
cluster-custom-resources/
└── lvms-operator
    └── lvmcluster.yaml
```

### Incorrecto

```text
storage/
└── lvmcluster.yaml
```

---

## Buenas Prácticas

### Separar infraestructura y configuración

La instalación de operadores debe realizarse en:

```text
operators/
```

La configuración funcional debe mantenerse en:

```text
cluster-custom-resources/
```

La configuración común de almacenamiento debe mantenerse en:

```text
storage/
```

---

### Mantener StorageClasses versionadas

Todas las clases de almacenamiento deben gestionarse desde Git.

Evitar modificaciones manuales mediante:

```bash
oc edit storageclass
```

---

### Identificar claramente la clase por defecto

Verificar:

```bash
oc get storageclass
```

Estado esperado:

```text
(default)
```

Mantener una única clase por defecto salvo requerimientos específicos.

---

### Gestionar snapshots desde Git

Las `VolumeSnapshotClass` deben mantenerse bajo control de versiones para garantizar consistencia entre entornos.

---

## Verificaciones Operativas

### Storage Classes

```bash
oc get storageclass
```

---

### Volume Snapshot Classes

```bash
oc get volumesnapshotclass
```

---

### Persistent Volumes

```bash
oc get pv
```

---

### Persistent Volume Claims

```bash
oc get pvc -A
```

---

### Aplicación ArgoCD

```bash
oc get application storage -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## Troubleshooting

### PVC en estado Pending

Verificar:

```bash
oc get pvc -A
```

```bash
oc describe pvc <pvc-name>
```

Comprobar:

- StorageClass asignada.
- Disponibilidad del backend de almacenamiento.
- Estado del provisionador CSI.

---

### StorageClass no disponible

Verificar:

```bash
oc get storageclass
```

y:

```bash
oc describe storageclass <storageclass>
```

---

### Snapshot no creada

Verificar:

```bash
oc get volumesnapshot
```

```bash
oc get volumesnapshotcontent
```

---

### Provisionamiento fallido

Revisar:

```bash
oc get events -A --sort-by=.metadata.creationTimestamp
```

y los logs del operador responsable del almacenamiento.

---

## Recuperación

Durante una reconstrucción completa de la plataforma:

1. Se despliega la capa `operators`.
2. Se validan los operadores mediante los Health Checks definidos.
3. Se despliega la capa `platform`.
4. Se despliega la capa `storage`.
5. Los recursos dependientes definidos en `cluster-custom-resources` pueden aplicarse posteriormente.

Esta secuencia garantiza que los componentes consumidores de almacenamiento se desplieguen únicamente cuando la infraestructura subyacente esté disponible.

---

## Evolución Futura

La estructura actual está preparada para incorporar nuevos dominios de almacenamiento como:

```text
storage/
├── apps
├── lvms
├── odf
├── noobaa
├── storageclasses
└── volumesnapshotclasses
```

permitiendo escalar la plataforma sin necesidad de reorganizar la jerarquía GitOps existente.

---

## Principios de Diseño

- Gestión declarativa mediante GitOps.
- Separación entre infraestructura y configuración.
- Reutilización de recursos de almacenamiento comunes.
- Compatibilidad con múltiples tecnologías de almacenamiento.
- Trazabilidad completa de cambios.
- Despliegues reproducibles y auditables.
- Integración con estrategias de backup y disaster recovery.
- Compatibilidad con despliegues Day-0 y reconstrucciones completas de plataforma.
