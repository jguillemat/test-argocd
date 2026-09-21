# GitOps repository to WS02-SNO LAB

Repository for deploy GitOps configuration to OCP in ws02-sno lab.

La estructura del repositorio es 

├── bootstrap
│   └── argocd
│       ├── applications
├── cluster-config
│   └── apps
├── storage
│   └── apps
├── cluster-custom-resources
│   ├── apps
│   ├── lvms-operator
│   └── quay-ha
├── observability
│   ├── alerts
│   ├── apps
│   ├── dashboards
│   ├── logging
│   └── monitoring
├── operators
│   ├── apps
│   ├── cluster-logging
│   ├── loki-operator
│   ├── lvms-operator
│   └── openshift-cluster-observability-operator
├── platform
│   ├── apps
│   ├── dns-operator
│   ├── image-registry
│   ├── ingress
│   │   └── default
│   ├── kubeletconfig
│   ├── machineconfig
│   ├── machineconfigpool
│   ├── proxy
│   └── tuned
└── policies
    ├── apps
    ├── egressip
    ├── networkpolicies
    └── rbac
        ├── cluster-groups
        ├── cluster-rolebindings
        └── cluster-roles

Modelo de Sync-Waves recomendado

	Wave 0      Configuración Cluster  
			Namespaces
			AppProjects
			Secrets GitOps
			PullSecrets
	Wave 10     Policies/RBAC
			ClusterRoles
			ClusterRoleBindings
			Groups
			ServiceAccounts	
	Wave 20     Operadores Base
			OperatorGroup
			Subscription
			Namespace
	Wave 25	    Storage
			StorageClasses
	Wave 30     Operadores Infraestructura
			OperatorGroup
			Subscription
			Namespace	
	Wave 40	    Security
	Wave 50     Configuración de la plataforma
	Wave 60     Configuración CRD's
	Wave 70     Observabilidad
	
  - 00-cluster-config.yaml
  - 10-policies.yaml
  - 20-operators.yaml
  - 25-storage.yaml
# - 30-operators-infra.yaml
# - 40-security.yaml
  - 50-platform.yaml
  - 60-cluster-custom-resources.yaml
  - 70-observability.yaml


	
	
