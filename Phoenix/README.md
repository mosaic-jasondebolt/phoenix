# Phoenix Microservice
<img src="/Phoenix/images/logo.png" height="70px"/>

![Pipeline](/Phoenix/images/pipeline_1a.png)
![Pipeline](/Phoenix/images/pipeline_1b.png)


### Getting started
* Update all of the params....json files with your project info
* The ProjectName should match the name of this Git repo. Use all lower case, optionally with dashes, keep it short.
```

Make sure there are no dashes in the DatabaseNamePrefix or MasterUsername parameters in the
template-database-params JSON files.
```
* Execute the following commands in order, waiting for each to complete before running the next.
```
cd Phoenix
./deploy-vpc.sh create
./deploy-pipeline.sh create
./deploy-dev-database.sh create
./deploy-dev-ec2.sh create ecs
./deploy-dev-lambda.sh create
./deploy-dev-api.sh create
./deploy-dev-api-deployment.sh create
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
* Update the template-pipeline file with your project details.
```
cd Phoenix
./deploy-pipeline.sh create
./deploy-pipeline.sh update
```

### Deploying a local Docker container to the Dev ECS cluster (skips the pipeline)
* Update all of the template-ecs-{environment} param files with your information.
* Don't forget to specify which port you want to open on the container in the ecs param files.
```
./deploy-dev-ec2.sh [create | update] [path location of folder containing dockerfile]
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
            {"PhoenixSSM": "/microservice/{ProjectName}/global/project-name"},
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
