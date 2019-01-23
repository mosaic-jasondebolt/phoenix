# Phoenix Microservice
<img src="/Phoenix/images/logo.png" height="70px"/>

### Table of Contents

* [Creating a Phoenix project in a new AWS account](#creating-a-phoenix-project-in-a-new-aws-account)
* [VPC Setup](#vpc-setup)
* [AWS ACM Certificates](#aws-acm-certificates)
* [AWS S3 Buckets and ECR Repos](#aws-s3-buckets-and-ecr-repos)

![Pipeline](/Phoenix/images/pipeline_1a.png)
![Pipeline](/Phoenix/images/pipeline_1b.png)


### Creating a Phoenix project in a new AWS account

#### Configure the VPC's
* Add appropriate CIDR ranges in the template-vpc-params-dev.json, template-vpc-params-testing.json, and template-vpc-params-prod.json files.
* Ensure that all CIDR IP ranges are not currently used by any other Phoenix projects or other networks.
* Deploy the VPC's
```
$ cd Phoenix
$ ./deploy-vpc.sh create
```

#### Save the API docs user agent token in SSM parameter store for the account
* This is a secret token used to verify HTTP requests made to API documents served from the S3 bucket.
* This token can be shared by all Phoenix projects in a single AWS account.
* This token can saved in a browser using the Chrome browser plugin to add to the 'user-agent' header in requests.
* Usage of this token in the browser is optional, but it can be useful when accessing API docs from over VPN.
```
From you mac:
$ pwgen 32 -1

Save this token in the '/global/api-docs-user-agent' SSM parameter store parameter with the descripte "UserAgent used to authenticate with S3 static websites for API Documentation."
```


### Initial Phoenix Project Setup
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


### VPC Setup
### AWS ACM Certificates
### AWS S3 Buckets and ECR repos
