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

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-deployment-params-dev.json`
STACK_NAME=$PROJECT_NAME-api-deployment-$ENVIRONMENT

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create', 'update', or 'delete'."
    exit 1
fi

# Get the current API Gateway Deployment template from the stack, compare, and generate a new template.
#python api_gateway_deployment_rotator.py template-api-deployment-params-dev.json > template-api-deployment.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-api-deployment-params-dev.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-api-deployment.json

if [ $1 == "delete" ]
  then
    aws cloudformation delete-stack --stack-name $STACK_NAME
  else
    # Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
    aws cloudformation $1-stack --stack-name $STACK_NAME \
        --template-body file://template-api-deployment.json \
        --parameters file://temp1.json \
        --capabilities CAPABILITY_IAM

    aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

    # Cleanup
    rm temp1.json
fi
