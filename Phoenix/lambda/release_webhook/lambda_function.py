import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac
import re
import base64

# Handler for receiving release events from GitHub.

# https://developer.github.com/v3/activity/events/types/#pushevent

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

GITHUB_API_URL = 'https://api.github.com'

class JSONObject:
  def __init__(self, dict):
      vars(self).update(dict)

# Assign python values to values return from gitlab JSON reqeuest object
false = False
true = True
null = None

def get_github_access_token():
    print('getting github access token')
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/github/access-token'.format(os.environ['PROJECT_NAME']),
        WithDecryption=True
    )
    return response['Parameter']['Value']

def get_github_release_secret():
    print('getting github release secret')
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/github/release-secret'.format(os.environ['PROJECT_NAME']),
        WithDecryption=True
    )
    return response['Parameter']['Value']

def get_microservice_bucket_name():
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/bucket-name'.format(os.environ['PROJECT_NAME']),
        WithDecryption=False
    )
    return response['Parameter']['Value']


def get_release_environments():
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/release-environments'.format(os.environ['PROJECT_NAME']),
        WithDecryption=False
    )
    result = response['Parameter']['Value']
    return [val.strip() for val in result.split(',')]  # ['staging', 'qa', ...]


def lambda_handler(event, context):
    print(event)

    # I used Lambda proxy integration here.
    github_signature = event['headers']['X-Hub-Signature']
    secret = get_github_release_secret()
    signature = hmac.new(secret.encode(), event['body'].encode(), "sha1")
    expected_signature = 'sha1=' + signature.hexdigest()

    print('github_signature: ', github_signature)
    print('expected_signature: ', expected_signature)

    if not hmac.compare_digest(github_signature, expected_signature):
        return {
            "isBase64Encoded" : "false",
            "statusCode": "401",
            "headers": {},
            "body": "Unauthorized!"
        }
    else:
        # For a full list of events: https://developer.github.com/v3/activity/events/types/#pushevent
        print('EVENT:')
        print(event)
        json_obj = json.dumps(event, indent=4)
        print('JSON_OBJECT:')
        print(json_obj)
        obj = json.loads(json_obj, object_hook=JSONObject)
        print('OBJECT:')
        print(obj)
        body = json.loads(obj.body, object_hook=JSONObject)
        print('BODY:')
        print(body)

        if not hasattr(body, 'pusher'):
            raise Exception('Object is not a push request!')

        repo_name = body.repository.name

        is_create_branch_push_event = body.before == '0000000000000000000000000000000000000000'
        is_delete_branch_push_event = body.after == '0000000000000000000000000000000000000000'
        print('is_create_branch_push_event: ', is_create_branch_push_event)
        print('is_delete_branch_push_event: ', is_delete_branch_push_event)
        
        return {
            "isBase64Encoded" : "false",
            "statusCode": "200",
            "headers": {},
            "body": "Success!"
        }
