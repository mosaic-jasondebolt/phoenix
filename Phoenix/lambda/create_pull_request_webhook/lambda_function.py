import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac

# Creates a GitHub webhook within GitHub for sending pull request webhooks

# For the full GitHub Pull Request REST API:
# https://developer.github.com/v3/activity/events/types/#pullrequestevent

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

def get_github_access_token():
    response = ssm_client.get_parameter(
        Name='/microservice/phoenix/global/github/access-token',
        WithDecryption=False
    )
    return response['Parameter']['Value']

def lambda_handler(event, context):
    print(event)
