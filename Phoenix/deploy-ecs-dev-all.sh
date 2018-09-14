#!/bin/bash
set -e

# Update a RDS + ECS deployment.

# USAGE:
#   ./deploy-ecs-all-dev.sh create

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-macro-params.json)
DOMAIN_NAME=$(jq -r '.Parameters.Domain' template-macro-params.json)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-deployment-params-dev.json`

if [ $1 == "create" ]
  then
    ./deploy-database-dev.sh $1
    ./deploy-ec2-dev.sh $1
    ./deploy-ecs-main-task-dev.sh $1
fi
