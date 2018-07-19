#!/bin/bash
set -e

# Deploys an API Gateway Custom Domain and Route53 A Record pointing to the CloudFront distro for the API.

# USAGE:
#   ./deploy-api-custom-domain-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-api-custom-domain-dev.sh create
#   ./deploy-api-custom-domain-dev.sh update

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-custom-domain-params-dev.json`
STACK_NAME=$PROJECT_NAME-api-custom-domain-$ENVIRONMENT

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-api-custom-domain-params-dev.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-api-custom-domain.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $STACK_NAME \
    --template-body file://template-api-custom-domain.json \
    --parameters file://temp1.json \
    --capabilities CAPABILITY_IAM

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

# Cleanup
rm temp1.json
