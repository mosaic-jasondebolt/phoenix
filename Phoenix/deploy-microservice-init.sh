#!/bin/bash
set -e

# Creates a complete microservice project.
#
# USAGE
#   ./deploy-microservice-init.sh

# Replace any phoenix SSM parameter keys if they exist
PROJECT_NAME=`jq -r '.Parameters.ProjectName' ssm-microservice-params.json`
python search_and_replace.py . /microservice/phoenix/ /microservice/$PROJECT_NAME/

echo "Deploying SSM parameters"
./deploy-ssm-microservice-params.sh create

echo "Deploying microservice"
./deploy-microservice.sh create

echo "Deploying merge request pipeline"
./deploy-merge-request-pipeline-api.sh create

echo "Deploying microservice cleanup"
./deploy-microservice-cleanup.sh create
