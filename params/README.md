# docker-pipeline-demo

##### Manually creating or updating the ECS deployment
```
python parameters_generator.py dev.json > temp.json

===== IMPORTANT!!!!!! =======
MAKE SURE TO REPLACE THE HARD CODED IMAGE VERSION IN PLACE OF "IMAGE_TAG" or "latest" in the ecs_task_definition_params_dev.json file before creating
or updating the dev stack!!!
=============================

aws cloudformation create-stack --stack-name <stack_name> --template-body file://ecs_task_definition.json --parameters file://temp.json

aws cloudformation update-stack --stack-name <stack_name> --template-body file://ecs_task_definition.json --parameters file://temp.json
```

##### Calculate Costs
```
python parameters_generator.py ecs_task_definition_params_prod.json > temp.json

aws cloudformation estimate-template-cost --template-body file://ecs_task_definition.json --parameters file://temp.json
```
