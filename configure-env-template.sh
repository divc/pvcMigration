#!/bin/bash

export ENVIRONMENT_TO_CONFIGURE="AWS"                          # Select between GCP | AWS | BOTH 

#GCP Environment Variables 
export GCP_WORKING_NAMESPACE="default"
export GCP_CLUSTER_NAME="pvc-cluster"
export GCP_REGION="us-west1"
export GCP_PVC_NAME=""
export GCP_BACKUP_NAMESPACE="sample"
export GCP_VELERO_SERVICE_ACCOUNT_NAME="velero-sa"
export GCP_VELERO_ROLE_NAME="velerotest.server.role"
export GCP_VELERO_ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)
export GCP_BUCKET="pvc-cluster-valero-bucket"


#AWS Environment Variables 
export AWS_CLUSTER_NAME="divyanshc-cluster"
export AWS_REGION="us-west-1"
export AWS_NAMESPACE="default"
export AWS_PVC_NAME=""
export AWS_NEW_NAMESPACE="sample"
export AWS_VELERO_SERVICE_ACCOUNT_NAME="velero-sa"
export AWS_VELERO_POLICY_NAME="velero-policy"
export AWS_BUCKET="pvc-valero-bucket" #Change the bucket name based on the naming convention and policies 