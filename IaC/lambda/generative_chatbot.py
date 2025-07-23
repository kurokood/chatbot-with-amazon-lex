import json
import boto3
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Lex V2 client
lex_client = boto3.client('lexv2-runtime')

# Environment variables
BOT_ID = os.environ.get('BOT_ID')
BOT_ALIAS_ID = os.environ.get('BOT_ALIAS_ID')
LOCALE_ID = os.environ.get('LOCALE_ID', 'en_US')

def lambda_handler(event, context):
    """
    Lambda function to handle API Gateway requests and forward them to Lex V2
    """
    logger.info(f"Event received: {json.dumps(event)}")
    
    # Get the origin from the request headers
    origin = event.get('headers', {}).get('origin') or event.get('headers', {}).get('Origin') or 'https://chatbot.monvillarin.com'
    logger.info(f"Origin: {origin}")
    
    # Common CORS headers - using specific origin
    cors_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': origin,  # Use the actual origin
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,Accept,Origin',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
        'Access-Control-Allow-Credentials': 'true'
    }
    
    # Handle OPTIONS request (CORS preflight)
    if event.get('httpMethod') == 'OPTIONS':
        logger.info("Handling OPTIONS preflight request")
        # Return a simple 200 OK with CORS headers for preflight requests
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({
                'status': 'success',
                'message': 'CORS preflight successful'
            })
        }
    
    try:
        # Get request body
        body = json.loads(event.get('body', '{}'))
        
        # Extract parameters from request
        user_id = body.get('userId', 'default-user')
        message = body.get('message', '')
        session_attributes = body.get('sessionAttributes', {})
        
        if not message:
            return {
                'statusCode': 400,
                'headers': cors_headers,
                'body': json.dumps({'error': 'Message is required'})
            }
        
        # Call Lex V2 API
        response = lex_client.recognize_text(
            botId=BOT_ID,
            botAliasId=BOT_ALIAS_ID,
            localeId=LOCALE_ID,
            sessionId=user_id,
            text=message,
            sessionState={
                'sessionAttributes': session_attributes
            }
        )
        
        logger.info(f"Lex response: {json.dumps(response, default=str)}")
        
        # Format response for frontend
        formatted_response = {
            'message': response.get('messages', [{}])[0].get('content', '') if response.get('messages') else '',
            'dialogState': response.get('sessionState', {}).get('intent', {}).get('state', ''),
            'sessionAttributes': response.get('sessionState', {}).get('sessionAttributes', {}),
            'slots': response.get('sessionState', {}).get('intent', {}).get('slots', {})
        }
        
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps(formatted_response)
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps({'error': str(e)})
        }