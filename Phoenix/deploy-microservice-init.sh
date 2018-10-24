#!/bin/bash
set -e

# Creates a complete microservice project.
#
# USAGE
#   ./deploy-microservice-init.sh

echo "Deploying ACM SSL Certificates"
./deploy-acm-certificates.sh create

echo "Deploying global SSM parameters and CloudFormation Macro"
./deploy-ssm-globals-macro.sh create

echo "Deploying pipeline"
./deploy-pipeline.sh create

echo "Deploying merge request webhook"
echo "Make sure to update your git repo with this webhook"
./deploy-merge-request-webhook.sh create

echo "Deploying release webhook"
echo "Make sure to update your git repo with this webhook"
./deploy-release-webhook.sh create

echo "Deploying microservice cleanup"
./deploy-microservice-cleanup.sh create
