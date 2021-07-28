## This is the Pod to Pod (p2p) PoC

In it's most basic form, this PoC is designed to move files from one cluster to another.  It does so by starting a source pod in the source cluster.  It then attaches itself to a PVC (it will also create a test PVC and files).  Once this pod is running, we then create a destination pod in the destination cluster.  This pod attaches to a PVC as needed.  Once souce and destination pods are running, the destination pod will use rsh (remote shell, like ssh) to create a secure tunnel and transfer files from the source PVC to the destination PVC.

The machine running this script should have access to the clusters, kubectl, and an internet connection.

## How to run

### 1.) Populate the [config-secrets.sh](pv-migrations/configure-secrets.sh) script with proper information.  - Run the `configure-secrets.sh` script.

This file should have 3 sections:

#### AWS ACCESS KEY AND SECRET 
This is used for connecting to S3, so it need the appropriate IAM permissions to WRITE to an S3 bucket
```
echo "
[default]
aws_access_key_id=
aws_secret_access_key=
" > ./pocs/via-s3/source/secrets/credentials
```

#### GCP Service Account Secret Keyfile 
This is used for connecting to GCS, so it need the appropriate IAM permissions to READ from the GCS bucket
```
echo '
{
  "type": "service_account",
  "project_id": "",
  "private_key_id": "",
  "private_key": ""
  ........
}
' | tee ./pocs/via-s3/dest/secrets/service-account.json ./pocs/p2p/dest/secrets/service-account.json
```

#### OIDC token 
This is used for authenication from the destination cluster to source cluster;  This gets added to the pod as an env var (for p2p PoC only)
```
export SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id 0oa54lqa1zwIWea3P2p7 | jq -r .status.token)
```

### 2.) In the dest/scripts folder, there is a `config` file which is a kubeconfig that is copied to the destination cluster.  

Make sure this file has:
* the SOURCE cluster information populated
* the current context set to the SOURCE cluster
* a user for that cluster with the name `default-user`

### 3.) Edit and run the ./p2p.sh script

Before we can run the `p2p.sh` script, we need to change some parameters in the file.  This is the main configuration point.  This can be improved many way but at this point we need to change these variables:

#### Source
```
GENERATE_DATA="yes"     # yes/no; will generate 10 64mb test files in the PV
CREATE_TEST_PVC="yes"   # yes/no; will create a test PVC using the SOURCE_PVC name
SRC_NS="alfa"           # namespace to deploy job into (and optionally test PVC)
SOURCE_PVC="source-sidecar-pvc-p2p" # source PVC name
SRC_KUBE_CONTEXT="dev.k8s.au-infrastructure.com"
```

#### Destination
```
CREATE_TEST_PVC="yes"                               # yes/no; will create a test PVC using the DEST_PVC name
DEST_NS="default"                                   # dest namespace to deploy job into (and optionally test PVC)
CLUSTER="au-poc-cluster-dest"                       # dest cluster name
DEST_PVC="dest-sidecar-pvc-p2p"                     # dest PVC name
DEST_ZONE="us-east4-a"                              # dest zone
DEST_PROJECT="gft-amer-rtai-test"                   # dest project id
SERVICE_ACCOUNT_PATH="secrets/service-account.key"  # Populate with service account path (do not change unless you changed the code or file location)
```

At this point, we can run the the `p2p.sh` script which will start the `source` pods and wait until the pod is ready by checking a file for status.  Once ready, the script will continue with running the `dest` pod scripts on the destination
