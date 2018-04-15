# Phoenix Microservice

##### Creating and updating a microservice project
```
* Update the template-microservice file with your project details.
* ./deploy-microservice.sh create
* ./deploy-microservice.sh update
```

##### Deploying a local Docker container to the Dev ECS cluster (skips the pipeline)
```
* Update all of the template-ecs-{environment} param files with your information.
* Don't forget to specify which port you want to open on the container in the ecs param files.
./deploy-ecs-dev.sh [create | update] [path location of folder containing dockerfile]
```

##### Deploying the entire microservice to production.
Just merge to the master branch and watch the pipeline go.
