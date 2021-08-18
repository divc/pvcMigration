# Cloud Native PV Migration 

## Moving data from PVC in k8s cluster hosted on AWS to GKE on GCP.  

Challenges: 
 - PVC is an immutable resource and cannot be changed when switching from one cloud provider to another. 
 - Storage classes from one cloud provider are incompatible with another cloud provider unless 3rd party storage class is used which results in acquiring licenses and increase in cost
 - Accessing data residing on a RWO (ReadWriteOnce) PVC can only be done by the pod located in the same node that has access to the persistent volume. 
 - Transfer of data without disrupting live traffic
 - Short time window to transfer huge amounts of data. 
 - Slow or bandwidth limited network tunnel between the cloud providers for data migration. 


## Implementation 

### Installing Velero on GCP/AWS  

 - Step 1: Make a copy of configure-env-template.sh file and name it as configure-env.sh
 - Step 2: Fill the environment variables according to the cloud provider
 - Step 3: Make sure you have environment variable $ENVIRONMENT_TO_CONFIGURE set to either "AWS", "GCP" or "BOTH"
 - Step 4: Run setup-velero.sh file

```
chmod 666 ./setup-velero.sh
./setup-velero.sh
```

### Annotating pods so that restic can take raw data backup  

Annotate the pods that are attached to the PVCs for which backups are needed as follows: 

```
kubectl -n <NAMESPACE_NAME> annotate pod/<POD_NAME> backup.velero.io/backup-volumes=<VOLUME_MOUNT_NAME>
```

Examples: 

```
kubectl -n default annotate pod/wordpress-86999dc7d9-4mslz backup.velero.io/backup-volumes=wordpress-persistent-storage

kubectl -n default annotate pod/wordpress-mysql-866bf45d65-ccsrq backup.velero.io/backup-volumes=mysql-persistent-storage
```


### Backing up resources specific to a namespace using Velero 

```
velero backup create <BACKUP_NAME> --include-resources <COMMO_SEPERATED_RESOURCES_TO_BE_BACKED_UP> --include-namespaces <NAMESPACE> --include-cluster-resources=true --wait
```

Example: 

```
velero backup create pv-backup-1 --include-resources secrets,services,deployments,pvc,pv --include-namespaces default --include-cluster-resources=true --wait
```

### Running pod to pod shell scipt (p2p.sh)

#### Step 1.) Configure
Create a copy of [./p2p/configure-template.sh](./configure-template.sh) named `configure.sh`.  Fill out the required input parameters.
This file should have this information:

##### Source Cluster Information
```bash
export SRC_NS="default"                                    # source namespace to deploy job into (and optionally test PVC)
export SOURCE_PVC=""                                       # source PVC name
export SRC_KUBE_CONTEXT=""                                 # source kube-context
export SOURCE_CLUSTER_CERT=""                              # source cluster X509 certificate
export SOURCE_CLUSTER_API_HOST=""                          # source cluster API Host
``` 
##### Source Data Related Settings
```bash
export GENERATE_DATA="no"                                  # yes/no; will generate 10 64mb test files in the PV
export CREATE_DEST_TEST_PVC="no"                           # yes/no; will create a test PVC using the SOURCE_PVC name
```

##### Source Cluster Token
Use the appropriate option for your use case
```bash
# GKE
#export SRC_OIDC_TOKEN=$(gcloud config config-helper --format="value(credential.access_token)")

# OKTA
export SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id <CLIENTID> | jq -r .status.token)

# EKS
#export SRC_OIDC_TOKEN=$(aws eks get-token --cluster-name <CLUSTERNAME> | jq -r '.status.token')
```


##### Destination Cluster Information
```bash
export DEST_NS="default"                                   # dest namespace to deploy job into (and optionally test PVC)
export CLUSTER=""                                          # dest cluster name
export DEST_PVC=""                                         # dest PVC name
export DEST_ZONE="us-east4-a"                              # dest zone
export DEST_PROJECT=""                                     # dest project id
```
##### Destination Data Related Settings
```bash
export CREATE_TEST_PVC="no"                                # yes/no; will create a test PVC using the DEST_PVC name
```

##### GCP Service Account info (for local kubectl runtime)
```bash
export SERVICE_ACCOUNT_PATH=""                            # Full path to a service account key that has access to GKE Developer roles
```

#### 2.) Run the ./p2p.sh script

At this point, we can run the the `p2p.sh` script which will start the `source` pods and wait until the pod is ready by checking a file for status.  Once ready, the script will continue with running the `dest` pod scripts on the destination