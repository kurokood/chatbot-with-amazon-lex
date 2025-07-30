import boto3
from datetime import datetime, timedelta
import json
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Content-Type': 'application/json'
    }
    
    try:
        # Debug: Print the event structure
        print(f"Event received: {json.dumps(event, indent=2)}")
        
        # Handle OPTIONS request for CORS preflight
        # API Gateway v2 uses 'requestContext.http.method' instead of 'httpMethod'
        http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
        
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        # Get query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        start_date_str = query_params.get('startDate')
        end_date_str = query_params.get('endDate')

        if not start_date_str or not end_date_str:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing required query parameters: startDate or endDate'
                })
            }

        try:
            start_date = datetime.fromisoformat(start_date_str)
            start_date = start_date - timedelta(days=1)
            end_date = datetime.fromisoformat(end_date_str)
        except ValueError as e:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': f'Invalid date format: {str(e)}'
                })
            }

        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('approved') & boto3.dynamodb.conditions.Key('date').between(start_date.isoformat(), end_date.isoformat())
        )

        approved_meetings = response['Items']

        while 'LastEvaluatedKey' in response:
            response = table.query(
                IndexName='StatusIndex',
                KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('approved') & boto3.dynamodb.conditions.Key('date').between(start_date.isoformat(), end_date.isoformat()),
                ExclusiveStartKey=response['LastEvaluatedKey']
            )
            approved_meetings.extend(response['Items'])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(approved_meetings)
        }
        
    except Exception as e:
        print(f"Error in get_meetings: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
