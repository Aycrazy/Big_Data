#!/usr/bin/bash

set -x -e

# bucket should be created and used on s3
SPARK_BUCKET=andrew-s3-emrcluster
# name of the key pair ex: MyKeyPair
SPARK_KEY_PAIR=andrew-emrcluster

# push bootstrap file up to s3 #
aws s3 cp lsdm-emr-script.sh s3://${SPARK_BUCKET}/bootstrap/lsdm-emr-script.sh

#create spark cluster
# aws emr create-cluster --name "Spark Cluster" \
# --release-label emr-5.11.1 \
# --use-default-roles \
# --applications Name=Spark Name=Ganglia \
# --ec2-attributes \
#     KeyName=${SPARK_KEY_PAIR},SubnetId=subnet-f7610dbf,EmrManagedMasterSecurityGroup=sg-9eef32e9,EmrManagedSlaveSecurityGroup=sg-72f72a05 \
# --instance-type=m4.xlarge \
# --instance-count 5 \
# --region us-east-1 \
# --log-uri s3://andrew-s3-emrcluster \
# --emrfs Consistent=False \
# --bootstrap-actions Path="s3://andrew-s3-emrcluster/bootstrap/lsdm-emr-script.sh",Args=[--python-packages,"numpy matplotlib"]

aws emr create-cluster --name 'Spark Cluster' \
--release-label emr-5.11.1 \
--applications Name=Spark Name=Ganglia \
--ec2-attributes KeyName=${SPARK_KEY_PAIR},EmrManagedMasterSecurityGroup=sg-9eef32e9,EmrManagedSlaveSecurityGroup=sg-72f72a05,SubnetId=subnet-f7610dbf \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.2xlarge \
   InstanceGroupType=CORE,InstanceCount=4,InstanceType=m4.2xlarge \
--region us-east-1 \
--use-default-roles \
--emrfs Consistent=False \
--log-uri s3://andrew-s3-emrcluster \
--bootstrap-actions Path="s3://andrew-s3-emrcluster/bootstrap/lsdm-emr-script.sh",Args=[]

