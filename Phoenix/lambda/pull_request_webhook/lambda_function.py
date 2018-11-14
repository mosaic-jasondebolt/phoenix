import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac
import base64

# Handles GitHub merge request events

# For the full GitHub Pull Request REST API:
# https://developer.github.com/v3/activity/events/types/#pullrequestevent

cloudformation_client = boto3.client('cloudformation')
secretsmanager_client = boto3.client('secretsmanager')

def get_github_secret():
    response = secretsmanager_client.get_secret_value(
        SecretId='GitHubPullRequestSecret'
    )
    return response['SecretString']


def lambda_handler(event, context):
    print(event)

    # I used Lambda proxy integration here.
    github_signature = event['headers']['X-Hub-Signature']
    secret = get_github_secret()
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
