#!/bin/bash
set -e

# Update a RDS + ECS deployment.

# USAGE:
#   ./deploy-ecs-all-dev.sh create

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
DOMAIN_NAME=$(aws ssm get-parameter --name /microservice/phoenix/domain | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-deployment-params-dev.json`

if [ $1 == "create" ]
  then
    ./deploy-database-dev.sh $1
    ./deploy-ec2-dev.sh $1
    ./deploy-ecs-main-task-dev.sh $1
fi
