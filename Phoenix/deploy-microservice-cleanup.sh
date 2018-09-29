#!/bin/bash
set -e

# Creates a microservice cleanup resources.
#
# USAGE
#   ./deploy-microservice-cleanup.sh [create | update]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Convert create/update to uppercase
OP=$(echo $1 | tr '/a-z/' '/A-Z/')

CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-macro-params.json)
ORGANIZATION_NAME=$(jq -r '.Parameters.OrganizationName' template-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-macro-params.json)
MICROSERVICE_BUCKET_NAME=$ORGANIZATION_NAME-$PROJECT_NAME-microservice
STACK_NAME=$PROJECT_NAME-microservice-cleanup
ENVIRONMENT='all'
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
CHANGE_SET_NAME=$VERSION_ID

aws s3 sync . s3://$MICROSERVICE_BUCKET_NAME/cloudformation --exclude "*" --include "template-pipeline-cleanup.json" --delete

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-pipeline-cleanup.json

aws cloudformation create-change-set --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME \
    --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-pipeline-cleanup.json \
    --change-set-type $OP \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $CLOUDFORMATION_ROLE

aws cloudformation wait change-set-create-complete \
    --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

# Let's automatically execute the change-set for now
aws cloudformation execute-change-set --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME
