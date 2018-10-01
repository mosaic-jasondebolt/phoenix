#!/bin/bash
set -e

# Deploys a Jenkins instance.

# USAGE:
#   ./deploy-jenkins.sh
#
# DO NOT try to update this stack as a volume snapshot may not be automatically created.
# To update this stack, delete the current Jenkins stack, record the ID of the snapshot
# that gets automatically saved, and use the snapshot ID in the 'snapshotId' stack
# parameter before running this script to create a new jenkins stack retored with
# the previous volume.
#
# To see how this looks, look at the DeletionPolicy of the volume in the jenkins template:
#
#     "VarLibJenkins": {
#      "DeletionPolicy": "Snapshot",
#       ...
#
# EXAMPLES:
#   ./deploy-jenkins.sh
#
#   Where,
#     version_id is the number at the end of the stack name.

# Check for valid arguments
if [ $# -ne 0 ];
  then
    echo "Incorrect number of arguments supplied. This script takes no arguments"
    exit 1
fi

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-ssm-globals-macro-params.json)
DNS_PREFIX=$(jq -r '.Parameters.DnsPrefix' template-jenkins-params.json)
STACK_NAME=$PROJECT_NAME-jenkins-$DNS_PREFIX
ENVIRONMENT='all'
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
CHANGE_SET_NAME=$VERSION_ID

# Regenerate the params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-jenkins-params.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-jenkins.json

aws cloudformation create-change-set --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME \
    --template-body file://template-jenkins.json \
    --parameters file://temp1.json \
    --change-set-type $OP \
    --capabilities CAPABILITY_IAM

aws cloudformation wait change-set-create-complete \
    --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

# Let's automatically execute the change-set for now
aws cloudformation execute-change-set --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

if [[ $1 == 'create' ]]; then
  aws cloudformation update-termination-protection --enable-termination-protection --stack-name $STACK_NAME
fi

# Cleanup
rm temp1.json
