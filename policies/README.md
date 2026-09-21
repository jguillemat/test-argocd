# Policies

## Descripción

El directorio `policies` contiene la configuración de seguridad, control de acceso y conectividad de red de la plataforma OpenShift.

Su objetivo es centralizar todas las políticas del clúster que regulan:

- Autorización y permisos.
- Control de acceso basado en roles (RBAC).
- Segmentación de red.
- Comunicación entre namespaces.
- Gestión de direcciones IP dedicadas para salida (EgressIP).

Esta capa proporciona los controles básicos de seguridad y gobierno sobre los que se apoya el resto de la plataforma.

---

## Objetivos

- Gestionar el modelo de acceso mediante GitOps.
- Aplicar el principio de mínimo privilegio.
- Centralizar la gestión de RBAC.
- Controlar la comunicación entre cargas de trabajo.
- Proporcionar trazabilidad completa de los cambios de seguridad.
- Garantizar configuraciones reproducibles y auditables.

---

## Arquitectura

```text
Policies
   │
   ├── RBAC
   │    ├── ClusterRoles
   │    ├── ClusterRoleBindings
   │    └── Groups
   │
   ├── Network Policies
   │    ├── Ingress
   │    └── Egress
   │
   └── EgressIP
```

---

## Estructura

```text
policies/
├── apps
├── egressip
├── networkpolicies
└── rbac
    ├── cluster-groups
    ├── cluster-rolebindings
    └── cluster-roles
```

---

## apps

Contiene las aplicaciones ArgoCD responsables de desplegar los recursos definidos en este dominio.

Ejemplo:

```text
policies/
└── apps
    └── policies.yaml
```

La aplicación será creada automáticamente desde la Root Application durante el proceso de bootstrap.

---

## rbac

Contiene todos los recursos relacionados con autorización y control de acceso.

### cluster-groups

Define grupos utilizados para asignar permisos dentro del clúster.

Ejemplos:

```text
platform-admins
cluster-admins
observability-admins
storage-admins
developers
```

Objetivos:

- Simplificar la asignación de permisos.
- Facilitar la integración con proveedores de identidad.
- Reducir la complejidad operativa.

---

### cluster-roles

Define los roles disponibles dentro del clúster.

Ejemplo:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
```

Casos habituales:

```text
platform-admin
storage-admin
observability-admin
network-admin
readonly
```

---

### cluster-rolebindings

Asocia grupos o usuarios a los roles definidos.

Ejemplo:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
```

Responsabilidades:

- Asignación de permisos.
- Delegación de funciones.
- Gobierno de acceso al clúster.

---

## networkpolicies

Define la segmentación de red entre aplicaciones y namespaces.

Ejemplo:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
```

Casos habituales:

### Deny All

```text
Bloqueo total de tráfico
```

### Namespace Isolation

```text
Aislamiento entre namespaces
```

### Ingress Rules

```text
Permitir tráfico entrante específico
```

### Egress Rules

```text
Permitir tráfico saliente controlado
```

---

## egressip

Gestiona recursos EgressIP de OpenShift.

Ejemplos:

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressIP
```

Casos de uso:

- Conectividad hacia sistemas externos.
- Integración con firewalls corporativos.
- Restricciones de seguridad perimetral.
- Listas blancas de direcciones IP.

Ejemplo:

```text
Aplicación → Firewall corporativo → Dirección IP fija
```

---

## Dependencias

Antes de desplegar esta capa deben existir:

### Bootstrap

```text
bootstrap
```

### Cluster Config

```text
cluster-config
```

Esta capa no depende de operadores ni CRDs externos.

---

## Sync Wave

Las políticas se despliegan inmediatamente después de la configuración básica del clúster.

```yaml
argocd.argoproj.io/sync-wave: "20"
```

Secuencia:

```text
bootstrap
    │
cluster-config
    │
policies
    │
operators
```

---

## Recursos Gestionados

### Permitidos

```text
ClusterRole
ClusterRoleBinding
Group
NetworkPolicy
EgressIP
```

---

### No Permitidos

No almacenar en esta capa:

```text
OperatorGroups
Subscriptions
Custom Resources
MachineConfigs
StorageClasses
```

Estos recursos pertenecen a otros dominios funcionales.

---

## Buenas Prácticas

### Principio de Mínimo Privilegio

Asignar únicamente los permisos estrictamente necesarios.

Correcto:

```text
storage-admin
```

Incorrecto:

```text
cluster-admin
```

para tareas específicas de almacenamiento.

---

### Uso de Grupos

Asignar permisos a grupos en lugar de usuarios individuales.

Correcto:

```text
platform-admins
```

Incorrecto:

```text
juan.garcia
pedro.lopez
ana.martinez
```

Esto facilita la administración y la integración con LDAP o Identity Providers.

---

### Separar Roles y Asignaciones

Mantener una separación clara:

```text
cluster-roles
```

define permisos.

```text
cluster-rolebindings
```

asigna permisos.

---

### Aplicar Segmentación de Red

Definir explícitamente qué comunicaciones están permitidas.

Recomendado:

```text
Default Deny
```

y posteriormente abrir únicamente los flujos requeridos.

---

### Versionar Cambios de Seguridad

Cualquier modificación de:

```text
RBAC
NetworkPolicy
EgressIP
```

debe realizarse mediante Pull Request y revisión previa.

---

## Verificaciones Operativas

### Cluster Roles

```bash
oc get clusterroles
```

---

### Cluster Role Bindings

```bash
oc get clusterrolebindings
```

---

### Network Policies

```bash
oc get networkpolicy -A
```

---

### Egress IPs

```bash
oc get egressip
```

---

### Aplicación ArgoCD

```bash
oc get application policies -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## Troubleshooting

### Acceso Denegado

Verificar:

```bash
oc auth can-i <accion> <recurso>
```

Ejemplo:

```bash
oc auth can-i create pods
```

---

### ClusterRoleBinding Incorrecto

Verificar:

```bash
oc describe clusterrolebinding <binding>
```

Confirmar:

- Grupo correcto.
- ClusterRole correcto.
- Subjects correctamente definidos.

---

### NetworkPolicy Bloqueando Tráfico

Verificar:

```bash
oc get networkpolicy -A
```

y:

```bash
oc describe networkpolicy <policy>
```

Confirmar:

- Ingress permitido.
- Egress permitido.
- Selectores correctos.

---

### Problemas con EgressIP

Verificar:

```bash
oc get egressip
```

```bash
oc describe egressip
```

Confirmar:

```text
Assignments
Status
Node Allocation
```

---

## Recuperación

Durante una reconstrucción completa de la plataforma:

1. ArgoCD despliega `cluster-config`.
2. ArgoCD despliega `policies`.
3. Se aplican los controles de acceso y conectividad.
4. El resto de dominios continúan con el despliegue.

La correcta aplicación de esta capa garantiza que los operadores y servicios desplegados posteriormente hereden la configuración de seguridad esperada.

---

## Principios de Diseño

- Seguridad gestionada como código.
- Control de acceso mediante RBAC.
- Trazabilidad completa de cambios.
- Segmentación de red explícita.
- Gestión declarativa mediante GitOps.
- Aplicación del principio de mínimo privilegio.
- Compatibilidad 
