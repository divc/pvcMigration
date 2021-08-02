# This is the Pod to Pod (p2p) PoC

In it's most basic form, this PoC is designed to move files from one cluster to another.  It does so by starting a source pod in the source cluster.  It then attaches itself to a PVC (it will also create a test PVC and files).  Once this pod is running, we then create a destination pod in the destination cluster.  This pod attaches to a PVC as needed.  Once souce and destination pods are running, the destination pod will use rsh (remote shell, like ssh) to create a secure tunnel and transfer files from the source PVC to the destination PVC.

The machine running this script should have access to the clusters, kubectl, and an internet connection.

# How to run

## 1.) Configure
Create a copy of [./p2p/configure-template.sh](./configure-template.sh) named `configure.sh`.  Fill out the required input parameters.
This file should have this information:

### Source Cluster Information
```bash
export SRC_NS="default"                                    # source namespace to deploy job into (and optionally test PVC)
export SOURCE_PVC=""                                       # source PVC name
export SRC_KUBE_CONTEXT=""                                 # source kube-context
export SOURCE_CLUSTER_CERT=""                              # source cluster X509 certificate
export SOURCE_CLUSTER_API_HOST=""                          # source cluster API Host
``` 
### Source Data Related Settings
```bash
export GENERATE_DATA="no"                                  # yes/no; will generate 10 64mb test files in the PV
export CREATE_DEST_TEST_PVC="no"                           # yes/no; will create a test PVC using the SOURCE_PVC name
```

### Source Cluster Token
Use the appropriate option for your use case
```bash
# GKE
#export SRC_OIDC_TOKEN=$(gcloud config config-helper --format="value(credential.access_token)")

# OKTA
export SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id <CLIENTID> | jq -r .status.token)

# EKS
#export SRC_OIDC_TOKEN=$(aws eks get-token --cluster-name <CLUSTERNAME> | jq -r '.status.token')
```


### Destination Cluster Information
```bash
export DEST_NS="default"                                   # dest namespace to deploy job into (and optionally test PVC)
export CLUSTER=""                                          # dest cluster name
export DEST_PVC=""                                         # dest PVC name
export DEST_ZONE="us-east4-a"                              # dest zone
export DEST_PROJECT=""                                     # dest project id
```
### Destination Data Related Settings
```bash
export CREATE_TEST_PVC="no"                                # yes/no; will create a test PVC using the DEST_PVC name
```

### GCP Service Account info (for local kubectl runtime)
```bash
export SERVICE_ACCOUNT_PATH=""                            # Full path to a service account key that has access to GKE Developer roles
```

## 2.) Run the ./p2p.sh script

At this point, we can run the the `p2p.sh` script which will start the `source` pods and wait until the pod is ready by checking a file for status.  Once ready, the script will continue with running the `dest` pod scripts on the destination
