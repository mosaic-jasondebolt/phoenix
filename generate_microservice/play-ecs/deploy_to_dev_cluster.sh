#!/bin/bash

# Builds a docker image and Dockerfile from the local Play app,
# generates a random tag number and tags the image, updates
# the CloudFormation parameters file with the new image tag,
# and either creates or updates a CloudFormation stack which
# deploys the locally build docker image to the Dev ECS cluster in AWS.

# USAGE:
#   ./deploy_to_dev_cluster.sh [create | update]

# Generate a random version number to tag the docker image with
TAG_NUMBER=`python -c "import random; print random.randint(5,100000)"`
IMAGE_TAG=dev_$TAG_NUMBER


if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Pass in either 'create' or 'update'"
    exit 1
fi

# Create a backup of build.sbt
cp build.sbt backup.temp

# Replace the IMAGE_TAG string in build.sbt with the environment variable.
sed "s/IMAGE_TAG/$IMAGE_TAG/g" build.sbt > build.temp && mv build.temp build.sbt

# Build the Dockerfile and local docker image
sbt docker:publishLocal

# Restore our build.sbt to original condition
mv backup.temp build.sbt

# Obtain auth with AWS Elastic Container Rep
eval $(aws ecr get-login --no-include-email --region us-east-1)

# Push the local docker image to AWS Elastic Container Repo
docker push 057281004471.dkr.ecr.us-east-1.amazonaws.com/docker-pipeline-demo:$IMAGE_TAG

cd devops

# Make a backup of the dev params file.
cp ecs_task_definition_params_dev.json backup.temp

# Replace the IMAGE_TAG string in the dev params file with the environment variable.
sed "s/IMAGE_TAG/$IMAGE_TAG/g" ecs_task_definition_params_dev.json > ecs.temp && mv ecs.temp ecs_task_definition_params_dev.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py ecs_task_definition_params_dev.json > temp.json

# Restore our dev params file back to original condition.
mv backup.temp ecs_task_definition_params_dev.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name docker-pipeline-demo-dev-deploy --template-body file://ecs_task_definition.json --parameters file://temp.json
