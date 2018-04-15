/!/bin/bash

# Generates a random docker image tag, builds a docker image,
# updates the CloudFormation parameters file with the new image tag,
# and either creates or updates a CloudFormation stack which
# deploys the locally build docker image to the Dev ECS cluster in AWS.

# USAGE:
#   ./deploy-ecs-dev.sh [create | update] [location of docker file]
#
# EXAMPLES:
#   ./deploy-ecs-dev.sh update .
#   ./deploy-ecs-dev.sh update ecs
#   ./deploy-ecs-dev.sh create ecs/target/docker/stage

# Generate a random version number to tag the docker image with
#TAG_NUMBER=`python2.7 -c "import random; print random.randint(5,100000)"`
USERNAME=`echo $USER | tr . "-"` # Replace . in username with hyphen for CloudFormation naming convention.
TAG_NUMBER=$USERNAME
IMAGE_TAG=dev_$TAG_NUMBER
AWS_ACCOUNT_ID=`jq '.Parameters.AWSAccountId' template-microservice-params.json`
IMAGE_NAME=`jq '.Parameters.ProjectName' template-microservice-params.json`
AWS_REGION=`jq '.Parameters.ECRRegion' template-microservice-params.json`
ECR_REPO=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG


if [ $# -ne 2 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update' ad the location of the docker file"
    exit 1
fi

# Obtain auth with AWS Elastic Container Rep
eval $(aws ecr get-login --no-include-email --region us-east-1)

docker build -t $ECR_REPO $2

# Push the local docker image to AWS Elastic Container Repo
docker push $ECR_REPO

# Replace the IMAGE_TAG string in the dev params file with the $IMAGE_TAG variable
sed "s/IMAGE_TAG/$IMAGE_TAG/g" template-ecs-params-dev.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json > temp2.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name dev-ecs-$USERNAME \
    --template-body file://template-ecs.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
rm temp2.json
