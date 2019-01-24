# Phoenix Microservice
<img src="/Phoenix/images/logo.png" height="70px"/>

## Table of Contents

* [What is Phoenix?](#what-is-phoenix)
* [Phoenix Overview](#phoenix-overview)
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
Some of these CloudFormation files are global in scope, and some create stacks that are environment specific.
For example, the "template-pipeline.json" file creates the main CI/CD pipeline for your Phoenix project, so
this stack is global (created once). The "template-ec2.json" file, however, is environment specific, so there
can be multiple stack instances of this template (one for each dev/testing/prod/etc environment).

#### template-vpc.json
This is an environment specific stack.

#### template-jenkins.json
This is a global, non-environment specific CloudFormation stack.

#### template-acm-certificates.json
This is a global, non-environment specific CloudFormation stack.

#### template-s3-ecr.json
This is a global, non-environment specific CloudFormation stack.

#### template-ssm-globals-macro.json
This is a global, non-environment specific CloudFormation stack.

#### template-pipeline.json
This is a global, non-environment specific CloudFormation stack.

#### template-github-webhook.json
This is a global, non-environment specific CloudFormation stack.

#### template-pull-request-pipeline.json
This is a global, non-environment specific CloudFormation stack.

#### template-release-environments-pipeline.json
This is a global, non-environment specific CloudFormation stack.

#### template-microservice-cleanup.json
This is a global, non-environment specific CloudFormation stack.






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

