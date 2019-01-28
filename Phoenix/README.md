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
            * [template-api-deployment.json](#template-api-deploymentjson)
            * [template-ecs-task.json](#template-ecs-taskjson)
    * [CloudFormation JSON Parameter Files](#cloudformation-json-parameter-files)
        * [Environments](#environments)
            * [Dev Environment](#dev-environment)
                * [Dev Parameter Files](#dev-parameter-files)
                * [Dev Deploy Scripts](#dev-deploy-scripts)
            * [Testing Environment](#testing-environment)
            * [E2E Environment](#e2e-environment)
            * [Prod Environment](#prod-environment)
        * [Adding Environments](#adding-environments)
        * [Removing Environments](#removing-environments)
    * [Phoenix Networking](#phoenix-networking)
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
1) [CloudFormation JSON Template Files](#cloudformation-json-template-files)
2) [CloudFormation JSON Parameter Files](#cloudformation-json-parameter-files)
3) [Deployment Shell Scripts](#deployment-shell-scripts) (mostly used for developer specific clouds)
4) [CodeBuild buildspec.yml Files](#codebuild-buildspecyml-files) (These are like Jenkins jobs)
5) [Python Helper Scripts](#python-helper-scripts)
6) [Python 3.6 Lambda Functions](#python-36-lambda-functions)
7) [Example Dockerfile used for testing/debugging ECS deployments](#example-dockerfile)


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
This template contains Lambda functions and all resources required for deploying lambda functions, such as IAM roles
and security groups. Phoenix ships with a VPC proxy lambda function which can proxy HTTP requests from API Gateay to
to private instances in an ECS cluster. A example "Project" Lambda function which handles requests from API Gateway
is also provided. Note that Lambda functions that require access to private EC2 or ECS resources must be placed in
a VPC. 

##### template-cognito.json
This template creates AWS Cognito resources such as an AppClient and UserPool. Like all CloudFormation templates, this
template can be extended.

##### template-cognito-internals.json
This template creates AWS Cognito resources that are not fully supported in AWS CloudFormation, such as user pool auth
domains, resource servers, user pool clients, and route53 record sets. Cognito is one of the AWS services that doesn't have all resources covered/provisionable by CloudFormation. This template solves this problem by using an <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources-lambda.html"> AWS Lambda-backed Custom Resource</a> within the template. Within the template, a Lambda function
is created from the "lambda/cognito_internals" Python code, and invokes the code during stack create/update/delete operations.
After the lambda function is invoked, it returns data and control back to the CloudFormation stack. 

##### template-api-custom-domain.json
This template deploys a <a href="https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-custom-domains.html">custom domain name</a> for your API Gateway API endpoints. It also create an DNS record set
in Route53 which points to this custom domain. When you deploy an edge-optimized API, API Gateway sets up an Amazon CloudFront distribution and a DNS record to map the API domain name to the CloudFront distribution domain name. Requests for the API are then routed to API Gateway through the mapped CloudFront distribution.

##### template-api-documentation.json
This template deploys AWS resources required to support versioned API documentation. Resources include a static S3 website/bucket, Bucket policy, CloudFront distribution, Web Application Firewall ACL, WAF rules, and WAF predicates for managing API documentation access.

##### template-api.json
This template deploys your API Gateway REST API. This includes all API REST resources and methods, along with API
models, auth types, and any other API Gateway resources specific to an API.

##### template-api-deployment.json
This template deploys that API specified in "template-api.json". Note that the declaration of the API (template-api.json) is
deployed separately from the deployment of the API (template-api-deployment.json). This is because API Gateway deployments are static, immutable "snaphots in time" of a given API. Once an API has been deployed, it cannot be changed, only replaced. This template also contains an <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources-lambda.html"> AWS Lambda-backed Custom Resource</a> from the Python source code in the "lambda/api_internals" folder. The
lambda function updates the API Gateway with a custom method integration that adds custom headers to the request, as well
as altering the request body. I used a custom lambda function here to avoid dozens of identical hard coded Python code
within template-api.json.

##### template-ecs-task.json
This template generates all resources required for a single ECS task service. An ECS task can inlude up to 10 containers
(1 main container and 9 sidecar containers). If more than one service (which may include up to 10 containers) is required for your Phoenix project, you can create a new set of parameter files and create multiple stack instances of this template. There
are no limits to the number of services are containers that can be deployed from a Phoenix project. The only limits are AWS 
limits.

This is probably one of the more advanced CloudFormation templates within Phoenix. It can be used to deploy ECS tasks using
either Fargate or EC2. It deploys a CloudWatch logs group, a single task definition, an ECS service, an Application Load
Balancer along with ALB listeners, Auto Scaling rules/alarms/policies based on 500 response errors, security groups, and
a DNS record set that points to the ALB endpoint. There are also some predefined environment variables that are passed
into the ECS task, but these can be removed. The lambda password generator and RDS password retriever are legacy and
can probably also be removed.

Phoenix ships with 4 parameter files for this template (template-ecs-task-**main**-params-{dev,e2e,testing,prod}.json). If your Phoenix project requires, say, a worker service for processing images from an SQS queue, you would create 4 more template files (template-ecs-task-**images**-params-{dev,e2e,testing,prod}.json). Make sure to update all other relevant files
(buildspec.yml, template-pipeline.json, etc.) to ensure this new ECS service is deployed. 

### CloudFormation JSON Parameter Files
CloudFormation uses parameter files to deploy a single template to multiple environments. Currently, Phoenix ships with four
different environments (dev, e2e, testing, and prod).

Environments can be added, renamed, or removed entirely. 

#### Environments

##### Dev Environment
Phoenix supports multiple dev environments. There are 2 basic types of dev environments supported within Phoenix:

1. Developer specific
2. Github pull request specific

Developer Specific environments are environments used only by a given developer to assist in development of not
only application source code, but infrastructure source code (CloudFormation templates). Developers can have their
own SQS queues, lambda functions, ECS clusters, RDS instances, and API Gateway deployments. This makes feedback
loops for infrastructure very fast since it provides developers the confidence that their isolated clouds will
not impact production or any other environment.

These dev environments are complete "developer clouds" that deploy the exact same AWS resources that are deployed
to in production, although they may be less scalable (fewer compute resources, lower limit on cpu and memory, etc.) to save on costs. Each developer on your team may have their own developer environment.

###### Dev Parameter Files
When a new developer joins your project, they should run "python generate_dev_params.py dev{username}" where "username"
is an all lowercase (no dashes, underscores, or dots) alias for the developer. For example, developer Jane Doe
would run the command "python generate_dev_params.py devjane" to generate her dev CoudFormation parameter files. Since these
files are gitignored, they will show up in your IDE/filesystem but cannot be checked into Git.

All CloudFormation parameter files that end with "*-params-dev.json" are gitignored by default to keep different developer
parameter files from clashing with eachother. 

###### Dev Deploy Scripts
A dev deploy script is a shell script within Phoenix that matches the file pattern of "deploy-dev-*.sh". There are currently
13 such scripts, all of which deploy one or more dev environment CloudFormation stacks. All [Environment Specific Stacks](#environment-specific-stacks) have dev deployment scripts.

A developer will execute these scripts locally whenever AWS infrastructure changes are made via CloudFormation templates. For example, if a developer wants to add a new Lambda function to production, they would first add the function to "template-lambda.json" and run "deploy-dev-lambda.sh update" to deploy the lambda function into their dev environment, assuming their dev environment is already up and running. The developer would then test the function in their own isolated dev cloud. Once the developer is satisfied with the lambda function, they will create a new branch, a pull request, and the code will be merged into the master branch. Once the code is merged into the master branch, the lambda function is deployed into testing, e2e, and finally into production.

Note that developers do not have their own AWS CodePipelines within the Phoenix platform. Instead, developers deploy to one
stack at at time using one of the dev deploy scripts. Since pipelines work best when multiple stacks need to be created/updated together in a consistent, orchestrated way, pipelines are overkill for developer workflows.

Phoenix deploys all dev resources into the "dev" VPC provided by "template-vpc.json".

##### Testing Environment
The Testing environment is an isolated environment for deploying AWS resources used for testing before production. 
One a testing environment is deployed, a suite of tests can operate on the testing environment. These tests occur after
the testing environment is deployed to. Such tests may include integration tests, browser tests, load tests, and security
related tests on infrastructure. Phoenix deploys all testing resources into the "testing" VPC provided by "template-vpc.json".

##### E2E Environment
E2E stands for "End-to-End". This environment is intended to be used for an additional level of testing between the testing and production environments. The E2E stage may include very expensive or time consuming integration tests that could be decoupled from the main integration tests run in the testing environment. Like all environments shipped this Phoenix, this environment can be removed for most projects. Phoenix deploys all E2E resources into the "testing" VPC provided by "template-vpc.json". There is no need to create a separate VPC just for e2e environments.

##### Prod Environment

Phoenix deploys all prod resources into the "prod" VPC provided by "template-vpc.json".

#### Adding Environments
You can add more environments to your Phoenix project by doing the following.
1. Add the environment name "template-ssm-globals-macro-params.json"
    * Add the name of your new environment to the "PipelineEnvironments" comma delimited list.
    * Deploy the updated parameter to SSM with "./deploy-ssm-globals-macro.sh update"
2. Execute the "generate_environment_params.py" helper script to generate the parameter files locally.
    * Execute "python generate_environment_params.py {your-environment-name}"
    * See the docstring of the python generate_environment_params.py script for details.
3. Update the new environment's parameter files with appropriate values.
    * You should see "template-*-params-{your-new-environment}.json" files in your local Phoenix project.
4. Update "template-pipeline.json" with a pipeline stage for your new environment.
   * Copy the entire "DeployToTesting" section, paste to a different area of the template, and rename.
    ```
    {
      "Name": "DeployToTesting",
      "Actions": [
        {
          ...
        }
      ]
     }
    ```
5. Update the pipeline stack with "./deploy-pipeline.sh update"
6. Create a git commit and push your new parameter files to the master branch of your project.

#### Removing Environments
You can remove environments from your Phoenix project by doing the following.
1. Remove the environment name "template-ssm-globals-macro-params.json"
    * Remove the name of the environment from the "PipelineEnvironments" comma delimited list.
    * Deploy the updated parameter to SSM with "./deploy-ssm-globals-macro.sh update"
2. Execute the "generate_environment_params.py" helper script to generate the parameter files locally.
    * Execute "python generate_environment_params.py {your-environment-name} **--delete**"
    * See the docstring of the python generate_environment_params.py script for details.
3. Verify that the environment parameter files have been deleted in your local project's Phoenix folder:
    * You should no longer see "template-*-params-{your-new-environment}.json" files in your local Phoenix project.
4. Update "template-pipeline.json" with a pipeline stage for your new environment.
   * Remove the entire "DeployTo{name-of-environment}" section from within "template-pipeline.json":
    ```
    {
      "Name": "DeployTo{name-of-environment}",
      "Actions": [
        {
          ...
        }
      ]
     }
    ```
5. Update the pipeline stack with "./deploy-pipeline.sh update"
6. Create a git commit and push your new parameter files to the master branch of your project.

### Deployment Shell Scripts

### CodeBuild buildspec.yml Files

### Python Helper Scripts

### Python 3.6 Lambda Functions

### Example Dockerfile


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

