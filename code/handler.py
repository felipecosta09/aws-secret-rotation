import boto3
import os
import json
import uuid
from botocore.exceptions import ClientError

# Initialize the boto3 client
secret = boto3.client('secretsmanager')
sns = boto3.client('sns')

# Get environment variables
secret_name = os.environ['SECRET_NAME']
topic_arn = os.environ['TOPIC_ARN']

# Function to create a new secret value, replace by your own logic
def create_secret(secret_name):
    # Generate a new API key
    try:
        new_api_key = str(uuid.uuid4())
        secret = {
        "api_key": new_api_key
        }
        return json.dumps(secret)
    except Exception as e:
        print(f"Failed to generate a new secret value: {e}")

# Function to format the message log
def format_response(secret_name, response):
    formatted_response = {
    "RequestId": response['ResponseMetadata']['RequestId'],
    "Date": response['ResponseMetadata']['HTTPHeaders']['date'],
    "SecretId": secret_name,
    "Status": "Success" if response['ResponseMetadata']['HTTPStatusCode'] == 200 else "Failed",
    "HTTPStatusCode": response['ResponseMetadata']['HTTPStatusCode'],        
    }
    return formatted_response

# Send a notification to the SNS topic
def send_notification(message):
    try:
        response = sns.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message),
            Subject='Secret rotation completed'
        )
        print(f"Notification sent to {topic_arn}")
        return response
    except ClientError as e:
        print(f"Failed to send notification to {topic_arn}: {e}")

def lambda_handler(event, context):

    # Create a new secret
    new_secret = create_secret(secret_name)

    # Update the secret value
    try:       
        response = secret.put_secret_value(SecretId=secret_name, SecretString=new_secret)
        formatted_response_json = format_response(secret_name, response)
        print(f"Secret rotation completed")
        print(formatted_response_json)
        sns_notification = send_notification(formatted_response_json)
        print(sns_notification)
    except ClientError as e:
        print(f"Failed to update secret {secret_name}: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps("Secret rotation failed")
        }
    
    # Return a success message
    return {
        "statusCode": 200,
        "body": json.dumps("Secret rotation completed")
    }
