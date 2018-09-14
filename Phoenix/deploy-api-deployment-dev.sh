#!/bin/bash
set -e

# Deploys the current API Gateway configuration to the API Endpoint URL for the specified environment.

# USAGE:
#   ./deploy-api-deployment-dev.sh [create | update | delete]
#
# EXAMPLES:
#   ./deploy-api-deployment-dev.sh create
#   ./deploy-api-deployment-dev.sh update
#   ./deploy-api-deployment-dev.sh delete

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create', 'update', or 'delete'."
    exit 1
fi

# Convert create/update to uppercase
OP=$(echo $1 | tr '/a-z/' '/A-Z/')

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-macro-params.json)
ORGANIZATION_NAME=$(jq -r '.Parameters.OrganizationName' template-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-macro-params.json)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-deployment-params-dev.json`
STACK_NAME=$PROJECT_NAME-api-deployment-$ENVIRONMENT
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
CHANGE_SET_NAME=$VERSION_ID

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-api-deployment-params-dev.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-api-deployment.json

if [ $1 == "delete" ]
  then
    aws cloudformation delete-stack --stack-name $STACK_NAME
  else
    aws cloudformation create-change-set --stack-name $STACK_NAME \
        --change-set-name $CHANGE_SET_NAME \
        --template-body file://template-api-deployment.json \
        --parameters file://temp1.json \
        --change-set-type $OP \
        --capabilities CAPABILITY_IAM \
        --role-arn $CLOUDFORMATION_ROLE

    aws cloudformation wait change-set-create-complete \
        --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

    # Let's automatically execute the change-set for now
    aws cloudformation execute-change-set --stack-name $STACK_NAME \
        --change-set-name $CHANGE_SET_NAME

    aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

    # Cleanup
    rm temp1.json
fi
