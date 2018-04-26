# Phoenix Microservice
A full CI/CD solution for continuously building and deploying RDS, ECS, Lambda, and API Gateway resources.

<img src="logo.png" height="70px"/>

#### What ships with Phoenix?
##### Phoenix Microservice (template-microservice.json)
* Creates a local CodeCommit repo which stores all of your source code, buildspecs, templates, etc.
* Creates an ECR repo for your project's Docker images.
* Creates an AWS CodePipeline which will CI/CD any changes pushed to master.
* Creates an S3 bucket to store Lambda functions.
* Creates an S3 bucket to store load balancer logs.
* Creates an S3 bucket to store encrypted secrets using KMS.
* Creates an S3 bucket to store encrypted secrets using KMS.
* Creates an S3 bucket to store CodePipeline artifacts.
* Creates an S3 bucket to store CodeBuild artifacts.
* Creates an SNS topic which triggers on master branch commits.
* Creates an SNS topic which triggers on master branch commits.
* Creates a KMS key and KMS alias.
* Creates a CodePipeline service role.
* Creates a CodeBuild service role.
* Creates a CodePipeline approval SNS topic to notify pipeline approvers.
* Creates a Codebuild project for building Docker images, Lambda functions, and versioning.
* Creates a Codebuild project linting source code.
* Creates a Codebuild project unit testing source code.
* Creates a Codebuild project for running static analysis on source code.
* Creates a Codebuild project calculating AWS costs for deployed resources.
* Creates a Codebuild project for running integration tests.
* Creates a deployment script to create/update a dev RDS instance.
* Creates a deployment script to build docker images and push to a dev ECS cluster.
* Creates a deployment script to build, zip, and deploy a set of dev Lambda functions.
* Creates a deployment script to create/update an API Gateway REST API.
* Creates a deployment script to do "last 10" rolling deploys of API Gateway stages.
##### Phoenix Database (template-database.json)
* Jason to fill out
##### Phoenix ECS (template-ecs.json)
* Jason to fill out
##### Phoenix Lambda (template-lambda.json)
* Jason to fill out
##### Phoenix API Gateway (template-api.json)
* Jason to fill out


### Getting started
* Update all of the params....json files with your project info
* The ProjectName should match the name of this Git repo. Use all lower case, optionally with dashes, keep it short.
```
cd Phoenix
$ python search_and_replace.py . 714284646049 {your AWS AccountId}
$ python search_and_replace.py . phoenix {name of your project}
```
* Execute the following commands in order, waiting for each to complete before running the next.
```
cd Phoenix
./deploy-vpc.sh create
./deploy-microservice.sh create
./deploy-database-dev.sh create
./deploy-ecs-dev.sh create ecs
./deploy-lambda-dev.sh create
./deploy-api-dev.sh create
./deploy-api-deployment-dev.sh create
```
* If all of the above stacks complete, push to the master branch of the CodeCommit repo that was created.
```
git commit
git remote -v
git remote add origin	https://git-codecommit.us-east-1.amazonaws.com/v1/repos/{name of your repo}
git push origin master
```
* After you've pushed your changes, open the CodePipeline and watch it go.

### Creating and updating a microservice project
* Update the template-microservice file with your project details.
```
cd Phoenix
./deploy-microservice.sh create
./deploy-microservice.sh update
```

### Deploying a local Docker container to the Dev ECS cluster (skips the pipeline)
* Update all of the template-ecs-{environment} param files with your information.
* Don't forget to specify which port you want to open on the container in the ecs param files.
```
./deploy-ecs-dev.sh [create | update] [path location of folder containing dockerfile]
```

### Deploying the entire microservice to production.
Just merge to the master branch and watch the pipeline go.

### Best Practices
#### Consistency
* Please be consistent with naming conventions. Seriously. If you are unsure
how to name something like a CloudFormation Resource, Output Export Name, a
Parameter, or anything else, then please refer to existing code or ask someone
who knows. Consistency in naming conventions helps significantly with refactoring,
renaming, readability, seeing patterns arise, building abstractions, and detecting bugs.
Even if we do it differently than everyone else, consistency within the codebase
trumps all external conventions or style guides.

#### Stack Exports
* Use the pattern of {ProjectName}-{AWS service or function}-{Environment}-{Resource}. Here's an example:
```
"Outputs": {
    "EndpointAddress": {
      "Export": {
        "Name": {
          "Fn::Join": ["-", [
            {"Ref": "ProjectName"},
            "database",
            {"Ref": "Environment"},
            "EndpointAddress"
          ]]
        }
      },
      "Value": {
        "Fn::GetAtt": ["RDSCluster", "Endpoint.Address"]
      }
    }
  }
```
