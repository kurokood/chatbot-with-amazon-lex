import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Meetings')


def lambda_handler(event, context):
    response = table.query(
        IndexName='StatusIndex',
        KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('pending')
    )

    pending_meetings = response['Items']

    while 'LastEvaluatedKey' in response:
        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('pending'),
            ExclusiveStartKey=response['LastEvaluatedKey']
        )
        pending_meetings.extend(response['Items'])

    return pending_meetings
