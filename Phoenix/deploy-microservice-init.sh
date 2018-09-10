#!/bin/bash
set -e

# Creates a complete microservice project.
#
# USAGE
#   ./deploy-microservice-init.sh

# Replace any phoenix SSM parameter keys if they exist
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-macro-params.json`
PHOENIX_PREFIX='phoenix'
python search_and_replace.py . /microservice/$PHOENIX_PREFIX/ /microservice/$PROJECT_NAME/

echo "Deploying the CloudFormation Macro"
./deploy-macro.sh create

echo "Deploying SSM parameters"
./deploy-ssm-parameters.sh create

echo "Deploying microservice"
./deploy-microservice.sh create

echo "Deploying merge request pipeline"
./deploy-merge-request-pipeline-api.sh create

echo "Deploying microservice cleanup"
./deploy-microservice-cleanup.sh create
