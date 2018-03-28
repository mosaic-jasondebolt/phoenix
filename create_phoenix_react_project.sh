aws cloudformation create-stack \
    --stack-name phoenix-react \
    --template-body file://phoenix.json \
    --parameters \
        ParameterKey=ProjectName,ParameterValue=phoenix-react \
        ParameterKey=NotificationEmail,ParameterValue=jason.debolt@joinmosaic.com \
        ParameterKey=ProjectDescription,ParameterValue="The Mosaic Phoenix ReactJS starter project." \
    --capabilities CAPABILITY_NAMED_IAM
