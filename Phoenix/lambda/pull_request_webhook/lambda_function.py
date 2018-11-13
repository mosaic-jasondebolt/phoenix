import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac

# Handles GitHub merge request events

# For the full GitHub Pull Request REST API:
# https://developer.github.com/v3/activity/events/types/#pullrequestevent

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

def lambda_handler(event, context):
    print(event)

    github_signature = event['headers']['X-Hub-Signature']
    signature = hmac.new('test123'.encode(), json.dumps(event['body']).encode(), "sha1")
    expected_signature = 'sha1=' + signature.hexdigest()

    print(github_signature)
    print(expected_signature)

    if not hmac.compare_digest(github_signature, expected_signature):
        return {"status": "401"}
    else:
        return {"status": "200"}
