import json
import boto3

s3_client = boto3.client('s3')
cloudformation_client = boto3.client('cloudformation')

def lambda_handler(event, context):
    # TODO implement
    print(event)
    print(json.dumps(event, indent=2))
    event_trigger_name = event['Records'][0]['eventTriggerName']
    if event_trigger_name == 'DevAccessBranch':
        branch_created = event['Records'][0]['codecommit']['references'][0].get('created', False)
        branch_name = event['Records'][0]['codecommit']['references'][0]['ref'].split('/')[-1]
        repo_name = event['Records'][0]['eventSourceARN'].split(':')[-1]
        stack_name = '{0}-branch-{1}-review-pipeline'.format(repo_name, branch_name)

        custom_obj = json.loads(event['Records'][0]['customData'])
        bucket_name = custom_obj['MicroserviceBucketName']
        template_name = custom_obj['TemplateName']
        project_name = custom_obj['ProjectName']
        review_email = custom_obj['ReviewNotificationEmail']
        template_url = 'https://s3.amazonaws.com/{0}/cloudformation/{1}'.format(bucket_name, template_name)

        print('Stack name: {0}'.format(stack_name))
        print('Bucket name: {0}'.format(bucket_name))
        print('Project name: {0}'.format(project_name))
        print('Review email: {0}'.format(review_email))
        print('TemplateURL: {0}'.format(template_url))

        parameters=[
            {
                'ParameterKey': 'ProjectName',
                'ParameterValue': project_name
            },
            {
                'ParameterKey': 'ReviewNotificationEmail',
                'ParameterValue': review_email
            },
            {
                'ParameterKey': 'Environment',
                'ParameterValue': branch_name
            }
        ]

        if branch_created:
            print('branch {0} was created in repo {1}.'.format(branch_name, repo_name))
            response = cloudformation_client.create_stack(
                StackName=stack_name,
                TemplateURL=template_url,
                Parameters=parameters,
                Capabilities=['CAPABILITY_IAM'])
            print(response)
        else:
            print('branch {0} was deleted in repo {1}.'.format(branch_name, repo_name))
            response = cloudformation_client.delete_stack(StackName=stack_name)
            print(response)
    else:
        print('Unknown event trigger name of {0}'.format(event_trigger_name))
