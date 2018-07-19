import json
import boto3

PUT = 'PUT'
GET = 'GET'

sts_client = boto3.client('sts')

def lambda_handler(event, context):
    print(json.dumps(event))

    sts_response = sts_client.assume_role(
      # LMS 928181911649
      #RoleArn='arn:aws:iam::714284646049:role/PhoenixRole',
      RoleArn='arn:aws:iam::928181911649:role/PhoenixRole',
      RoleSessionName='PhoenixToPhoenixUIAdmins'
    )

    cloudformation_client = boto3.client(
      'cloudformation',
      aws_access_key_id=sts_response['Credentials']['AccessKeyId'],
      aws_secret_access_key=sts_response['Credentials']['SecretAccessKey'],
      aws_session_token=sts_response['Credentials']['SessionToken']
    )

    cloudformation_response = cloudformation_client.describe_stacks()
    print(json.dumps(cloudformation_response, indent=2, default=str))

    http_method = event['httpMethod']
    print(http_method)

    return {
      'statusCode': 200,
      'headers': {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      'body': json.dumps(cloudformation_response, indent=2, default=str)
    }
