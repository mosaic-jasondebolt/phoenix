# Phoenix Microservice
<img src="/Phoenix/images/logo.png" height="70px"/>

## Table of Contents

* [What is Phoenix?](#what-is-phoenix)
* [Phoenix Overview](#phoenix-overview)
    * [CloudFormation JSON Template Files](#cloudformation-json-template-files)
        * [Account Specific Stacks](#account-specific-stacks)
            * [template-vpc.json](#template-vpcjson)
            * [template-jenkins.json](#template-jenkinsjson)
        * [Project Specific Stacks](#project-specific-stacks)
            * [template-acm-certificates.json](#template-acm-certificatesjson)
            * [template-s3-ecr.json](#template-s3-ecrjson)
            * [template-ssm-globals-macro.json](#template-ssm-globals-macrojson)
            * [template-pipeline.json](#template-pipelinejson)
            * [template-github-webhook.json](#template-github-webhookjson)
            * [template-pull-request-pipeline.json](#template-pull-request-pipelinejson)
            * [template-release-environments-pipeline.json](#template-release-environments-pipelinejson)
            * [template-microservice-cleanup.json](#template-microservice-cleanupjson)
        * [Environment (dev, testing, prod, etc.) Specific Stacks](#environment-specific-stacks)
            * [template-ssm-environments.json](#template-ssm-environmentsjson)
            * [template-database.json](#template-databasejson)
            * [template-ec2.json](#template-ec2json)
            * [template-lambda.json](#template-lambdajson)
            * [template-cognito.json](#template-cognitojson)
            * [template-cognito-internals.json](#template-cognito-internalsjson)
            * [template-api-custom-domain.json](#template-api-custom-domainjson)
            * [template-api-documentation.json](#template-api-documentationjson)
            * [template-api.json](#template-apijson)
            * [template-deployment.json](#template-deploymentjson)
            * [template-ecs-task.json](#template-ecs-taskjson)
    * [Phoenixt Networking](#phoenix-networking)
    * [Phoenix Pipelines](#phoenix-pipelines)
        * [GitHub Pull Request](#github-pull-request)
        * [GitHub Pull Request Pipeline](#github-pull-request-pipeline)
* [One time configuration of your AWS account to work with Phoenix](#one-time-configuration-of-your-aws-account-to-work-with-phoenix)

## What is Phoenix
Phoenix is a platform for launching highly available, multi-environment, <a href="https://12factor.net/">Twelve Factor App</a> microservice projects on AWS with advanced support for CI/CD automation.

A Phoenix project ships with multi-environment VPC configuration, complex CI/CD pipeline infrastructure, GitHub webhook integration, central storage and propagation of project parameters/variables, and multiple developer specific clouds environments. 

Phoenix is not a framework and it does not hide anything, which can be overwhelming for those not deeply familiar with AWS and CloudFormation. A good starting point would be to study the "deploy-microservice-init.sh" file, as this is the file used to bootstrap a Phoenix project. When this script is invoked, over 30 CloudFormation stacks are created for your Phoenix project.


## Phoenix Overview
A Phoenix microservice is a Git repository with a "Phoenix" subdirectory. This Phoenix subdirectory includes the following file types:
1) CloudFormation JSON template files.
2) CloudFormation JSON parameter files.
3) Deployment shell scripts (mostly used for developer specific clouds).
4) CodeBuild buildspec.yml files (These are like Jenkins jobs).
5) Python helper scripts.
6) Python 3.6 Lambda functions.
7) An example Dockerfile used for testing/debugging ECS deployments.


### CloudFormation JSON Template Files
An AWS account may include multiple Phoenix projects, and each Phoenix project may include multiple environments like
"dev" for developer and pull-request resources, "testing" for testing/staging/qa resources, and "prod" for production
resources. Phoenix cloudformation templates are scoped to the account level, project level, and environment level.

The "template-vpc.json" file is an **account specific** as well as an **environment specific** stack. This template may create a dev VPC stack, a testing VPC stack, and a prod VPC stack. These VPC stacks can be shared by multiple Phoenix projects. 

The "template-pipeline.json" file is a **project specific** stack. This template is used to create a stack named "{project-name}-pipeline.json". This CI/CD pipeline is shared by all environments, so only one stack instance should be created for this template.

The "template-ec2.json" file is an **environment specific** stack. Stack names may include "{project-name}-ec2-testing" and
"{project-name}-ec2-prod".

#### Account Specific Stacks
The following templates are used to create stacks to used across the entire AWS account, possibly hosting several Phoenix projects. The stack name will be {template-name}.

##### template-vpc.json
Approximately 21 AWS resources are created including VPC's, Internet Gateways, NAT gateways, routing tables, private/public subnets configured for high availability, and VPC Elastic IP's. These VPC stacks export values important by many other stacks.

##### template-jenkins.json
While I highly recommend AWS CodeBuild rather than Jenkins for a number of reasons, this template can be used to spin up a single Jenkins node. This template is entirely optional, however.

#### Project Specific Stacks
The following templates are scoped to a single Phoenix project. Most of these templates are associated with a single stack.
The stack name will be {project-name}-{template-name}.

##### template-acm-certificates.json
This template creates several different ACM SSL certificates used for things like ECS endpoints, API Gateway endpoints, Cognito Auth endpoints, and S3 website endpoints, all of which are supported by Phoenix.

##### template-s3-ecr.json
This template creates an ECR repository for your projects docker images as well as several S3 buckets. Logging buckets are created for CodePipeline, CodeBuild, and Elastic Load Balancer Logs. Additional buckets are created for source code artifacts like Lambda source bundles and Phoenix CloudFormation templates. 

##### template-ssm-globals-macro.json
This template creates a <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-macros.html">CloudFormation Macro</a> and a set of global non-environment specific SSM parameters for your Phoenix project. The macro is a Lambda function that pre-processes CloudFormation templates and the SSM parameters are saved into SSM parameter store.

##### template-pipeline.json
This template creates a multi-environment AWS CodePipeline, GitHub webhook on the master branch, build/test/lint AWS CodeBuild jobs, and an CloudWatch rule which sends SNS notifications to the project email upon pipeline failure. This is one of the most important CloudFormation stacks of any Phoenix project.

##### template-github-webhook.json
This is neither a global nor environment specific template, but the template can have multiple stack instances. This template deploys a GitHub webhook on GitHub for one or more events, an API Gateawy endpoint, a Lambda webhook handler, a post webhook Lambda handler, and other resources required for launching GitHub webhooks. The API Gateway endpoint sits between GitHub and Lambda and it used to receive the webhook event from GitHub. This is a very powerful template that can potentially be used to created dozens of GitHub webhooks of different types. Currently Phoenix ships with two stacks (parameter files) for this template, one for pull requests (template-github-webhook-pull-request-params.json) and another for release events (template-github-webhook-release-params.json).

##### template-pull-request-pipeline.json
This is a pull request specific template, supporting multiple stack instances. Each stack instance of this template is associated with a GitHub pull request pipeline. This stack(s) associated with this template are created/updated/deleted
from within a Lambda function that listens for pull request events from GitHub.

##### template-release-environments-pipeline.json
Each stack instance of this template is associated with a release into a specific release environment. This stack(s) associated with this template are created/updated/deleted from within a Lambda function that listens for push events from GitHub where the branch matches the regular expression pattern "release-\d{8}$". See the "release_webhook" Lambda function in the lambda folder for details.

#### template-microservice-cleanup.json
This template creates an AWS CodeBuild job that destroys all AWS resources for one or more environments (dev, testing, prod, etc). The "buildspec-destory-microservice.yml" buildspec
deletes CloudFormation stacks in the appropriate order. A project admin can manually kick off this CodeBuild job to completely destory one or more Phoenix environments.

#### Environment Specific Stacks
The following templates are scoped to one or more environments (dev, testing, prod, etc) for a single Phoenix project.
There may be several stack instances per template, each scoped to an different environment. The stack name will be
{project-name}-{template-name}-{environment}.

##### template-ssm-environments.json
This template deploys environment specific SSM parameters for your project. Any kind of environment specific project parameters/config can be stored as SSM parameters in this template. Once deployed, these parameters are stored in SSM Parameter Store and made available to all other CloudFormation stacks.

Many teams store project configuration values in source code config files. This is a violation of the Twelve-Factor App
rule of <a href="https://12factor.net/config">store config in the environment, not the source code<a>. 
   
Phoenix has an easy solution for centrally storing project or environment specific configuration values and making them
available to AWS resources (EC2 instances, Lambda functions, ECS containers, CodeBuild jobs, etc.) via IAM policies.
This eliminates differences in dev/test/prod parity, increases visibility of configuration values, enhances security,
and provides a single "source of truth" for your project configuration values. All configuration values are stored in AWS SSM Parameter store, which is currently a free service.

If you look at the "template-ssm-environments.json" template, you'll see a "DescriptionParam" parameter with a key ending with "description". The value associated with this parameter is stored in SSM parameter store can can be accessed in other CloudFormation templates (See the "Description" value in the Outputs section of the "template-lambda.json" for an example of importing these values). Simply add environment specific parameters to the "template-ssm-environments.json" file
and add new config values in all of the "template-ssm-environments-params-{environment}.json" parameter files before
updating these stacks. All stored values will be made available to other authorized AWS resources.

The "PROJECTNAMELambdaMacro" transform at the top section of many CloudFormation templates as well as the "macro" lambda
function in the "Phoenix/lambda" folder make this possible.

##### template-database.json
This template deploys an Aurora MySQL cluster and supports
cluster restores from snapshots. A custom Lambda resource within the template auomatically generates a password for new
database instances, with some support for password rotation as well. There is also a CodeBuild job defined in this template
that can be used for database migrations within the CI/CD CodePipeline.

##### template-ec2.json
This template creates an EC2 launch configuration, auto scaling group, security groups, EC2 instances, load balancers, an other EC2 resources.

##### template-lambda.json


##### template-cognito.json

##### template-cognito-internals.json

##### template-api-custom-domain.json

##### template-api-documentation.json

##### template-api.json

##### template-deployment.json

##### template-ecs-task.json


### CloudFormation JSON Template Parameter Files

### Phoenix Networking
* All Phoenix projects ship with a CloudFormation template for creating VPC's.
* A Phoenix project can contain any number of VPC's, but there three environments supported (dev, testing, prod) out of the box.
* Multiple Phoenix projects within the same AWS account can use the same VPC's.
* The VPC CloudFormation stacks export values such as VPC and Subnet Id's to be imported by other CloudFormation stacks.
* Each VPC includes the minimal networking resources for high availability, including 2 private subnets and 2 public subnets per VPC, each in different availability zones.
* VPC templates can be modified if more or less networking resources are required.

<img src="/Phoenix/images/vpc-3.png"/>

### Phoenix Pipelines
* A Phoenix microservice includes one or more CI/CD pipelines, some permanent, some ephemeral.
* Each pipeline has a source stage, which is usually triggered from a Git repository webhook.
* There is also a build stage, which will build a set of immutable artifacts that will be later deployed to one or more environments.
* Both source code and artifacts can be scanned for security and/or static analysis.
* If the build, testing, and linting stages pass, the artifacts (lambda functions, docker images, etc.) are deployed into a testing environment.
* After the testing environment is deployed to, a set of integration tests and load tests may further test your microservice.
* All environments contain there own databases, lambda functions, ECS clusters, dynamoDB tables, SSM parameters, and API Gateway deployments.
* Finally, the artifacts are deployed to a production environment using blue/green deployment strategies for all AWS resources.
* Optionally, pull request specific ephemeral pipelines can be added if your team requires these.

#### GitHub Pull Request
![Pipeline1](/Phoenix/images/pull-request-pipeline-4.png)

#### GitHub Pull Request Pipeline
![Pipeline1](/Phoenix/images/pull-request-pipeline-1.png)
![Pipeline1](/Phoenix/images/pull-request-pipeline-2.png)
![Pipeline1](/Phoenix/images/pull-request-pipeline-3.png)


#### Master Branch Pipeline
![Pipeline](/Phoenix/images/pipeline_1a.png)
![Pipeline](/Phoenix/images/pipeline_1b.png)


## One time configuration of your AWS account to work with Phoenix

### Configure the VPC's
* These steps are only required for new Phoenix projects in NEW AWS accounts.
* Add appropriate CIDR ranges in the template-vpc-params-dev.json, template-vpc-params-testing.json, and template-vpc-params-prod.json files.
* Ensure that all CIDR IP ranges are not currently used by any other Phoenix projects or other networks.
* Deploy the VPC's
```
$ cd Phoenix
$ ./deploy-vpc.sh create
```

<img src="/Phoenix/images/vpc-1.png"/>

### Save the API docs user agent token in SSM parameter store for the account
* These steps are only required for new Phoenix projects in NEW AWS accounts.
* This is a secret token used to verify HTTP requests made to API documents served from the S3 bucket.
* This token can be shared by all Phoenix projects in a single AWS account.
* This token can saved in a browser using the Chrome browser plugin to add to the 'user-agent' header in requests.
* Usage of this token in the browser is optional, but it can be useful when accessing API docs from over VPN.

```
From you mac:
$ pwgen 32 -1
```

Save the above generated token in the '/global/api-docs-user-agent' SSM parameter store parameter with
the descripte "UserAgent used to authenticate with S3 static websites for API Documentation." It this key already exists
in SSM parameter store for the AWS account, you don't need to do anything.


### AWS CodeBuild GitHub OAuth authorization
* These steps are only required for new Phoenix projects in NEW AWS accounts.
* When using AWS CodeBuild with GitHub webhook integrations, there is a one time setup involving Oauth tokens for new AWS accounts.
* We will need to use a shared admin GitHub account to authorize these tokens rather than use user specific GitHub accounts.
* Sign out of your OneLogin account.
* Sign back into OneLogin as the "devops+mosaic-codebuild@joinmosaic.com" user. See lastpass for login credentials.
* Once logged in, click on the GitHub app within OneLogin.
* At the GitHub login screen, use the username and password specified in lastpass.
* Verify that you are logged into GitHub as the mosaic-codebuild user and not your mosaic github user.
* In the new AWS account, open the AWS CodeBuild console and a new job called "test".
* Create a simple CodeBuild job using GitHub as the source, and click on the "Connect to GitHub" button.
* A dialog box will appear where you can authorize "aws-codesuite" to access the GitHub organization.
* Now you can allow CloudFormation to automatically create GitHub webhooks associated with this AWS account.

<img src="/Phoenix/images/codebuild-github-1.png" width="500px"/>
<img src="/Phoenix/images/codebuild-github-2.png" width="300px"/>
<img src="/Phoenix/images/codebuild-github-3.png" width="300px"/>

## Initial Phoenix Project Setup
### Configuring the project config file
* All Phoenix projects have a file called "template-ssm-globals-macro-params.json" used for project wide configuration.


- Create DNS hosted zone.
    - Copy the ID of this hosted into into the HostedZoneId param of the project config file laster.
- Create NS record in main account
- Create GitHub repo
    - Add the DevOps+IT group and mosaic code build groups as admins to this repo.
- Update template-ssm-globals-macro-params.json file
- Run ‘pwgen 32 -1’ and save token in the ‘/global/api-docs-user-agent’ SSM parameter.
- In the AWS CodeBuild console
    - Make sure you are logged into GitHub as the mosaic-codebuild user
    - Create a CodeBuild project called ‘test’
    - In the Source section, link to GitHub using OAuth. 
    - Click the dialog box that pops up. You only need to do this once for the AWS account.
- Copy the mosaic-codebuild GitHub access token from lastpass
    - You will pass this token into the ‘./deploy-microservice-init.sh’ shell script.
- Run the ‘/deploy-microservice-init.sh’ shell script with the mosaic-codebuild access token
    - ./deploy-microservice-init.sh {token}
- After all stacks from the microservice-init script have been created, push to that master branch of the repo
- $ git push origin master.

