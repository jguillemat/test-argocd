# Cluster Configuration

## Descripción

El directorio `cluster-config` contiene la configuración base requerida para inicializar el clúster OpenShift antes del despliegue del resto de componentes de la plataforma.

Los recursos definidos en este directorio representan las dependencias fundamentales sobre las que se apoyan los dominios funcionales posteriores como:

- Policies
- Operators
- Platform
- Storage
- Cluster Custom Resources
- Observability

Esta capa debe contener únicamente configuraciones necesarias para preparar el entorno y no debe incluir configuraciones específicas de operadores o aplicaciones.

---

## Objetivos

- Establecer la configuración inicial del clúster.
- Proporcionar dependencias compartidas al resto de capas GitOps.
- Mantener la configuración base centralizada
