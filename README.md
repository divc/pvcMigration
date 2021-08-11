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

# Installing Velero on GCP/AWS  

Step 1: Make a copy of configure-env-template.sh file and name it as configure-env.sh
Step 2: Fill the environment variables according to the cloud provider 
Step 3: Make sure you have environment variable $ENVIRONMENT_TO_CONFIGURE set to either "AWS", "GCP" or "BOTH"
Step 4: Run setup-velero.sh file 

```
./setup-velero.sh
```

# Backing up cluster resources  