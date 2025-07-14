import json
import boto3


bot = boto3.client('lexv2-runtime')


def lambda_handler(event, context):

    user_input = json.loads(event['body'])['message']

    response = bot.recognize_text(
        botId='${aws_lex_bot.meety_bot.id}',
        botAliasId='TSTALIASID',
        localeId='en_US',
        sessionId='your_session_id',
        text=user_input
    )

    bot_response = response['messages'][0]['content']

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': True,
        },

        'body': json.dumps({'botResponse': bot_response})
    }
