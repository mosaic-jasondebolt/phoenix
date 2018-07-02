#!/bin/bash
set -e

# Creates a complete microservice project.
#
# USAGE
#   ./deploy-microservice-init.sh

echo "Deploying SSM parameters"
./deploy-ssm-microservice-params.sh create

echo "Deploying microservice"
./deploy-microservice.sh create

echo "Deploying merge request pipeline"
./deploy-merge-request-pipeline-api.sh create

echo "Deploying microservice cleanup"
./deploy-microservice-cleanup.sh create
