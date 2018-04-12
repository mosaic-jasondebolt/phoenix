# Creates a Phoenix project

aws cloudformation create-stack \
    --stack-name phoenix-phoenix \
    --template-body file://phoenix.json \
    --parameters \
        ParameterKey=ProjectName,ParameterValue=phoenix \
        ParameterKey=NotificationEmail,ParameterValue=jason.debolt@joinmosaic.com \
        ParameterKey=ProjectDescription,ParameterValue="The Mosaic Phoenix project." \
    --capabilities CAPABILITY_NAMED_IAM
