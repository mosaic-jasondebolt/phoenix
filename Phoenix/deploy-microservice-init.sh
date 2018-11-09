#!/bin/bash
set -e

# Creates a complete microservice project.
#
# For details on the {GitHub token} argument, see the deploy-ssm-github-token.sh script.
#
# USAGE
#   ./deploy-microservice-init.sh {GitHub token}

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in a Githab access token. See the 'deploy-ssm-github-token.sh' script."
    exit 1
fi

echo "Deploying ACM SSL Certificates"
./deploy-acm-certificates.sh create

echo "Deploying global SSM parameters and CloudFormation Macro"
./deploy-ssm-globals-macro.sh create

echo "Deploying SSM GitHub token"
./deploy-ssm-github-token.sh $1

echo "Deploying pipeline"
./deploy-pipeline.sh create

echo "Deploying merge request webhook"
echo "Make sure to update your git repo with this webhook"
./deploy-merge-request-webhook.sh create

echo "Deploying release webhook"
echo "Make sure to update your git repo with this webhook"
echo "If you require release environments, add environments to 'ReleaseEnvironments' param in template-ssm-globals-macro-params.json"
./deploy-release-webhook.sh create

echo "Deploying microservice cleanup"
./deploy-microservice-cleanup.sh create
