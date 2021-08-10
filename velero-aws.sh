#!/bin/sh

#NAMESPACE=$1
#PVC_NAME=$2
REGION=us-west-1
NAMESPACE=default
PVC_NAME=
NEW_NAMESPACE=sample
VELERO_SERVICE_ACCOUNT_NAME=velero-sa
VELERO_POLICY_NAME=velero
BUCKET=pvc-valero-aws-bucket #Change the bucket name based on the naming convention and policies 


aws s3api create-bucket \
    --bucket $BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION


aws iam create-user --user-name $VELERO_SERVICE_ACCOUNT_NAME

cat > aws-velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}"
            ]
        }
    ]
}
EOF


aws iam put-user-policy \
  --user-name $VELERO_SERVICE_ACCOUNT_NAME \
  --policy-name $VELERO_POLICY_NAME \
  --policy-document file://aws-velero-policy.json


aws iam create-access-key --user-name $VELERO_SERVICE_ACCOUNT_NAME

velero install --use-restic --provider aws --plugins velero/velero-plugin-for-aws:v1.2.1 --bucket $BUCKET --backup-location-config region=$REGION --snapshot-location-config region=$REGION --secret-file ./aws-credentials-velero --wait

echo "Velero configured and installed"