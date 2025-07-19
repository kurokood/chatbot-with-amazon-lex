import json
import boto3
import os
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Lex client
lex_client = boto3.client('lexv2-runtime')

# Environment variables
BOT_ID = os.environ['BOT_ID']
BOT_ALIAS_ID = os.environ['BOT_ALIAS_ID']
LOCALE_ID = os.environ['LOCALE_ID']

def lambda_handler(event, context):
    """
    API Gateway Lambda function for Generative AI chatbot
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse the request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        user_message = body.get('message', '')
        session_id = body.get('sessionId', f"session-{datetime.now().strftime('%Y%m%d%H%M%S')}")
        
        if not user_message:
            return create_error_response(400, "Message is required")
        
        # Call Lex with the user message
        lex_response = lex_client.recognize_text(
            botId=BOT_ID,
            botAliasId=BOT_ALIAS_ID,
            localeId=LOCALE_ID,
            sessionId=session_id,
            text=user_message
        )
        
        logger.info(f"Lex response: {json.dumps(lex_response)}")
        
        # Extract the bot response
        bot_messages = []
        if 'messages' in lex_response:
            for message in lex_response['messages']:
                if message.get('contentType') == 'PlainText':
                    bot_messages.append(message.get('content', ''))
        
        # Combine all messages
        bot_response = '\n'.join(bot_messages) if bot_messages else "I'm sorry, I didn't understand that. Could you please rephrase?"
        
        # Get session attributes for context
        session_attributes = lex_response.get('sessionState', {}).get('sessionAttributes', {})
        
        # Get intent information - with our single intent approach, we're less concerned with the intent name
        intent_info = lex_response.get('sessionState', {}).get('intent', {})
        intent_name = intent_info.get('name', 'MeetingAssistant')
        intent_state = intent_info.get('state', 'Unknown')
        
        # Create response
        response_body = {
            'botResponse': bot_response,
            'sessionId': session_id,
            'intentName': intent_name,
            'intentState': intent_state,
            'sessionAttributes': session_attributes,
            'timestamp': datetime.now().isoformat()
        }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps(response_body)
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return create_error_response(400, "Invalid JSON in request body")
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_error_response(500, f"Internal server error: {str(e)}")

def create_error_response(status_code, message):
    """Create a standardized error response"""
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps({
            'error': message,
            'timestamp': datetime.now().isoformat()
        })
    }

# Handle OPTIONS requests for CORS
def handle_options():
    """Handle CORS preflight requests"""
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': ''
    }