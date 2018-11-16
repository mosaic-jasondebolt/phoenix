import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac
import base64
import random
import string

# Handles GitHub merge request events

# For the full GitHub Pull Request REST API:
# https://developer.github.com/v3/activity/events/types/#pullrequestevent

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

def get_random_secret(password_length=20):
    password = ''
    char_set = string.ascii_uppercase + string.ascii_lowercase + string.digits + '$'
    while '$' not in password:
        password = ''.join(random.sample(char_set * 6, int(password_length)))
    return password

def put_github_pull_request_secret_secret():
    print('putting github pull request secret')
    response = ssm_client.put_parameter(
        Name='/microservice/phoenix/global/github/pull-request-secret',
        Description='GitHub pull request secret.',
        Value=get_random_secret(64),
        Type='SecureString',
        Overwrite=True
    )
    print(response)

def get_github_pull_request_secret_secret():
    print('getting github pull request secret')
    response = ssm_client.get_parameter(
        Name='/microservice/phoenix/global/github/pull-request-secret',
        WithDecryption=True
    )
    print(response)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    print(event)

    # I used Lambda proxy integration here.
    github_signature = event['headers']['X-Hub-Signature']
    secret = get_github_pull_request_secret_secret()
    signature = hmac.new(secret.encode(), event['body'].encode(), "sha1")
    expected_signature = 'sha1=' + signature.hexdigest()

    print(github_signature)
    print(expected_signature)

    if not hmac.compare_digest(github_signature, expected_signature):
        return {
            "isBase64Encoded" : "false",
            "statusCode": "401",
            "headers": {},
            "body": "Unauthorized!"
        }
    else:
        return {
            "isBase64Encoded" : "false",
            "statusCode": "200",
            "headers": {},
            "body": "Success!"
        }
