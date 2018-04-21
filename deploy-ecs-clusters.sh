#!/bin/bash
set -e

# Generates ECS clusters

# USAGE:
#   ./deploy-ecs-clusters.sh [create | update]

PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

aws cloudformation validate-template --template-body file://template-ecs-clusters.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-ecs-clusters \
    --template-body file://template-ecs-clusters.json \
    --parameters ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME
