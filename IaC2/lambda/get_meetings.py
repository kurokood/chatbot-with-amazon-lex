import boto3
from datetime import datetime, timedelta
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Meetings')


def lambda_handler(event, context):

    start_date_str = event['queryStringParameters'].get('startDate')
    end_date_str = event['queryStringParameters'].get('endDate')

    if not start_date_str or not end_date_str:
        return {
            'statusCode': 400,
            'body': json.dumps('Missing required query parameters: startDate or endDate')
        }

    start_date = datetime.fromisoformat(start_date_str)
    start_date = start_date - timedelta(days=1)
    end_date = datetime.fromisoformat(end_date_str)

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

    return approved_meetings
