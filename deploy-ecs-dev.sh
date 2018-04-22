#!/bin/bash
set -e

# Generates a random docker image tag, builds a docker image,
# updates the CloudFormation parameters file with the new image tag,
# and either creates or updates a CloudFormation stack which
# deploys the locally build docker image to the Dev ECS cluster in AWS.

# USAGE:
#   ./deploy-ecs-dev.sh [create | update] [location of docker file]
#
# EXAMPLES:
#   ./deploy-ecs-dev.sh update .   --> Dockerfile in project root dir.
#   ./deploy-ecs-dev.sh update ecs   --> Dockerfile in ecs dir.
#   ./deploy-ecs-dev.sh create ecs/target/docker/stage

AWS_ACCOUNT_ID=`aws sts get-caller-identity --output text --query Account`
AWS_REGION=`aws configure get region`
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
ENVIRONMENT=`jq -r '.Parameters.Environment' template-ecs-params-dev.json`
# Allow developers to name the environment whatever they want, supporting multiple dev environments.
IMAGE_TAG=$ENVIRONMENT

IMAGE_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
ECR_REPO=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG


# Check for valid arguments
if [ $# -ne 2 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update' and the location of the docker file"
    exit 1
fi

# Obtain auth with AWS Elastic Container Rep
eval $(aws ecr get-login --no-include-email --region $AWS_REGION)

docker build -t $ECR_REPO $2

# Push the local docker image to AWS Elastic Container Repo
docker push $ECR_REPO

# Replace the IMAGE_TAG string in the dev params file with the $IMAGE_TAG variable
sed "s/IMAGE_TAG/$IMAGE_TAG/g" template-ecs-params-dev.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json > temp2.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-ecs.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-ecs-$ENVIRONMENT \
    --template-body file://template-ecs.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_NAMED_IAM

# Cleanup
rm temp1.json
rm temp2.json
