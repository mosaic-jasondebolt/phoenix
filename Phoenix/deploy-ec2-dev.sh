#!/bin/bash
set -e

# Creates or updates AWS ECS resources required to run one or more ECS tasks/services.

# USAGE:
#   ./deploy-ec2-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-ec2-dev.sh create
#   ./deploy-ec2-dev.sh update

AWS_ACCOUNT_ID=`aws sts get-caller-identity --output text --query Account`
AWS_REGION=`aws configure get region`
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-ec2-params-dev.json`
STACK_NAME=$PROJECT_NAME-ec2-$ENVIRONMENT

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-ec2-params-dev.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-ec2.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $STACK_NAME \
    --template-body file://template-ec2.json \
    --parameters file://temp1.json \
    --capabilities CAPABILITY_NAMED_IAM

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

# Cleanup
rm temp1.json
