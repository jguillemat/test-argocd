#!/bin/bash

# -----------------------------------------------------------------------
# Inicializar repositorio "bootstrap"
# -----------------------------------------------------------------------
mkdir -p bootstrap 

# -----------------------------------------------------------------------
# Inicializar repositorio "cluster-config"
# -----------------------------------------------------------------------
mkdir -p cluster-config cluster-config/apps

# -----------------------------------------------------------------------
# Inicializar repositorio "platform"
# -----------------------------------------------------------------------
mkdir -p platform platform/{apps,cluster-certificates,dns-operator,image-registry,ingress/default,machinconfigpool,machineconfig,oauth,proxy,tuned}

# -----------------------------------------------------------------------
# Inicializar repositorio "operators"
# -----------------------------------------------------------------------
mkdir -p operators operators/{apps,cluster-logging,openshift-cluster-observability-operator}

echo "# test-argocd" >> README.md  

git init
git add .
git commit -m "Initial structure for testing"
git branch -M main

git remote add origin git@github.com:jguillemat/test-argocd.git
git push -u origin main

#
# mkdir -p apps argocd/{projects,applications/{dev,staging,production}}
#
#
