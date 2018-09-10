#!/bin/bash
set -e

# Creates SSM parameters for a microservice.
#
# USAGE
#   ./deploy-ssm-params.sh [create | update]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Convert create/update to uppercase
OP=$(echo $1 | tr '/a-z/' '/A-Z/')

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-macro-params.json)
STACK_NAME=$PROJECT_NAME-ssm-microservice-params
ENVIRONMENT='all'
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
CHANGE_SET_NAME=$VERSION_ID

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-ssm-parameters.json

aws cloudformation create-change-set --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME \
    --template-body file://template-ssm-parameters.json \
    --change-set-type $OP \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $CLOUDFORMATION_ROLE

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
