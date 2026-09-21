# Observability

## Descripción

El directorio `observability` contiene la configuración relacionada con la monitorización, recopilación de métricas, centralización de logs, alertado y visualización de información operativa de la plataforma OpenShift.

Su objetivo es proporcionar visibilidad end-to-end sobre el estado de los componentes de infraestructura, operadores, servicios de plataforma y aplicaciones desplegadas en el clúster.

Todos los recursos definidos en esta capa son gestionados mediante GitOps a través de ArgoCD, garantizando trazabilidad, auditoría y reproducibilidad de la configuración.

---

## Objetivos

- Centralizar la observabilidad de la plataforma.
- Gestionar de forma declarativa métricas, logs, alertas y dashboards.
- Facilitar el troubleshooting operativo.
- Detectar incidencias de forma proactiva.
- Proporcionar capacidad de análisis histórico.
- Soportar la operación diaria de OpenShift.

---

## Arquitectura

```text
                    OpenShift Cluster
                            │
                            ▼
               OpenShift Observability Stack
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   Monitoring           Logging            Alerting
        │                   │                   │
        ▼                   ▼                   ▼
 Prometheus             LokiStack        PrometheusRule
 AlertManager     ClusterLogForwarder
        │
        ▼
 Dashboards
```

---

## Estructura

```text
observability/
├── alerts
├── apps
├── dashboards
├── logging
└── monitoring
```

---

## Apps

Contiene las aplicaciones ArgoCD encargadas de desplegar los distintos componentes de observabilidad.

Ejemplo:

```text
observability/
└── apps
    └── observability.yaml
```

La aplicación es creada automáticamente por la Root Application durante el proceso de bootstrap.

---

## Alerts

Contiene las reglas de alertado personalizadas para la plataforma.

Ejemplos:

```text
alerts/
├── infrastructure-alerts.yaml
├── ingress-alerts.yaml
├── platform-alerts.yaml
├── storage-alerts.yaml
└── operators-alerts.yaml
```

Recursos habituales:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
```

Responsabilidades:

- Detección temprana de incidencias.
- Supervisión de capacidad.
- Control de disponibilidad.
- Seguimiento de estados degradados.

---

## Dashboards

Contiene dashboards personalizados para Grafana u otras plataformas de visualización.

Ejemplos:

```text
dashboards/
├── cluster-overview.json
├── infrastructure-health.json
├── logging-overview.json
├── operators-overview.json
└── storage-overview.json
```

Objetivos:

- Visualización operativa.
- Seguimiento de capacidad.
- Supervisión de tendencias.
- Análisis de rendimiento.

---

## Logging

Contiene la configuración relacionada con la gestión de logs del clúster.

Ejemplos:

```text
logging/
├── clusterlogforwarder.yaml
├── lokistack.yaml
└── retention.yaml
```

Recursos habituales:

```yaml
ClusterLogForwarder
```

```yaml
LokiStack
```

Responsabilidades:

- Recolección de logs de infraestructura.
- Recolección de logs de aplicaciones.
- Almacenamiento centralizado.
- Gestión de retención.
- Búsqueda y análisis de eventos.

---

## Monitoring

Contiene la configuración relacionada con métricas y monitorización.

Ejemplos:

```text
monitoring/
├── cluster-monitoring-config.yaml
├── user-workload-monitoring-config.yaml
├── podmonitors
├── servicemonitors
└── prometheusrules
```

Recursos habituales:

```yaml
ServiceMonitor
```

```yaml
PodMonitor
```

```yaml
PrometheusRule
```

Responsabilidades:

- Monitorización de infraestructura.
- Monitorización de operadores.
- Monitorización de aplicaciones.
- Exposición de métricas personalizadas.
- Recopilación histórica de datos.

---

## Dependencias

Antes de desplegar esta capa deben haberse completado correctamente las siguientes fases:

### Cluster Configuration

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

Operadores requeridos:

```text
cluster-logging
loki-operator
openshift-cluster-observability-operator
```

---

### Platform

```text
platform
```

---

### Storage

```text
storage
```

---

### Cluster Custom Resources

```text
cluster-custom-resources
```

Por ejemplo:

```text
LokiStack
ClusterLogging
ClusterLogForwarder
```

---

## Sync Wave

La capa de observabilidad se despliega una vez que toda la infraestructura y los servicios dependientes están disponibles.

```yaml
argocd.argoproj.io/sync-wave: "80"
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
      │
observability
```

---

## Health Checks

La salud de esta capa depende principalmente de los siguientes recursos:

### LokiStack

Estado esperado:

```text
Ready=True
```

Validado mediante Health Check global de ArgoCD.

---

### ClusterLogging

Estado esperado:

```text
Ready=True
```

Validado mediante Health Check global de ArgoCD.

---

### ClusterLogForwarder

Estado esperado:

```text
Ready
```

Permite garantizar que los logs están siendo procesados correctamente.

---

## Recursos Gestionados

### Logging

```text
LokiStack
ClusterLogging
ClusterLogForwarder
```

---

### Monitoring

```text
ServiceMonitor
PodMonitor
PrometheusRule
```

---

### Dashboards

```text
Grafana Dashboards
Operational Dashboards
Capacity Dashboards
```

---

### Alerting

```text
PrometheusRule
Alert Routing
Notification Policies
```

---

## Buenas Prácticas

### Separar Logging y Monitoring

Correcto:

```text
logging/
monitoring/
```

Evitar:

```text
misc/
```

---

### Mantener Dashboards Versionados

Todos los dashboards deben almacenarse en Git.

Correcto:

```text
dashboards/
├── cluster-overview.json
├── storage-overview.json
└── platform-overview.json
```

---

### Gestionar Alertas mediante GitOps

Todas las reglas Prometheus deben mantenerse bajo control de versiones.

Evitar:

- Creación manual desde consola.
- Cambios directos en producción.
- Configuraciones no documentadas.

---

### Priorizar Alertas Operativas

Se recomienda monitorizar al menos:

```text
Node Availability
MachineConfigPool Status
Operator Health
Storage Capacity
CPU Utilization
Memory Utilization
Ingress Availability
Platform Services
```

---

## Verificaciones Operativas

### Estado de Loki

```bash
oc get lokistack -A
```

Estado esperado:

```text
Ready=True
```

---

### Estado de Cluster Logging

```bash
oc get clusterlogging -A
```

Estado esperado:

```text
Ready=True
```

---

### Estado del ClusterLogForwarder

```bash
oc get clusterlogforwarder -A
```

---

### Service Monitors

```bash
oc get servicemonitors -A
```

---

### Pod Monitors

```bash
oc get podmonitors -A
```

---

### Prometheus Rules

```bash
oc get prometheusrules -A
```

---

### Aplicación ArgoCD

```bash
oc get application observability -n openshift-gitops
```

Resultado esperado:

```text
Sync Status: Synced
Health Status: Healthy
```

---

## Troubleshooting

### LokiStack en estado Progressing

Verificar:

```bash
oc describe lokistack -A
```

Y posteriormente:

```bash
oc get pods -n openshift-logging
```

---

### ClusterLogging no disponible

Verificar:

```bash
oc describe clusterlogging -A
```

Y revisar los logs del operador:

```bash
oc logs deployment/cluster-logging-operator \
  -n openshift-logging
```

---

### Logs no visibles

Verificar la configuración del forwarder:

```bash
oc get clusterlogforwarder -A -o yaml
```

Comprobar:

```text
Inputs
Outputs
Pipelines
```

---

### Alertas no generadas

Verificar:

```bash
oc get prometheusrules -A
```

Y validar la expresión PromQL configurada.

---

### Dashboards vacíos

Verificar:

```bash
oc get servicemonitors -A
```

```bash
oc get podmonitors -A
```

Confirmar que Prometheus está recopilando métricas de los objetivos configurados.

---

## Recuperación

Durante una reconstrucción completa de la plataforma:

1. Se despliegan los operadores de observabilidad.
2. Se despliegan los Custom Resources asociados.
3. Se validan los Health Checks.
4. Se despliega automáticamente la capa `observability`.

No se recomienda desplegar esta capa antes de que los servicios de logging y monitoring estén completamente operativos.

---

## Evolución Futura

La estructura actual permite incorporar fácilmente nuevos componentes de observabilidad:

```text
observability/
├── alerts
├── dashboards
├── logging
├── monitoring
├── tracing
├── synthetic-monitoring
└── integrations
```

Ejemplos:

```text
Tempo
OpenTelemetry
Jaeger
Synthetic Checks
External Receivers
```

---

## Principios de Diseño

- Observabilidad gestionada como código.
- Configuración declarativa mediante GitOps.
- Separación entre métricas, logs, alertas y visualización.
- Integración con OpenShift Observability y Logging.
- Trazabilidad completa de cambios.
- Despliegues reproducibles y auditables.
- Soporte para operación, troubleshooting y capacity planning.
- Compatibilidad con despliegues Day-0 y recuperación ante desastres.
