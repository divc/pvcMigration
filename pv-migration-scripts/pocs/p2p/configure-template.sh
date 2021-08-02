#!/bin/bash

# Source 
export GENERATE_DATA="no"                                  # yes/no; will generate 10 64mb test files in the PV
export CREATE_TEST_PVC="no"                                # yes/no; will create a test PVC using the SOURCE_PVC name
export SRC_NS="default"                                    # source namespace to deploy job into (and optionally test PVC)
export SOURCE_PVC=""                                       # source PVC name
export SRC_KUBE_CONTEXT=""                                 # source kube-context
export SOURCE_CLUSTER_CERT=""                              # source cluster X509 certificate
export SOURCE_CLUSTER_API_HOST=""                          # source cluster API Host

# use the appropriate option for your use case
#GKE
#export SRC_OIDC_TOKEN=$(gcloud config config-helper --format="value(credential.access_token)")
#OKTA
export SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id <CLIENTID> | jq -r .status.token)
#EKS
#export SRC_OIDC_TOKEN=$(aws eks get-token --cluster-name <CLUSTERNAME> | jq -r '.status.token')

####################################################################################################

# Destination
export CREATE_TEST_PVC="no"                                # yes/no; will create a test PVC using the DEST_PVC name
export DEST_NS="default"                                   # dest namespace to deploy job into (and optionally test PVC)
export CLUSTER=""                                          # dest cluster name
export DEST_PVC=""                                         # dest PVC name
export DEST_ZONE="us-east4-a"                              # dest zone
export DEST_PROJECT=""                                     # dest project id

# GCP Service Account info (for local kubectl runtime)
export SERVICE_ACCOUNT_PATH=""