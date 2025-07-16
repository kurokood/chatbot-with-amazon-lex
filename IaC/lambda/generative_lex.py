import json
import boto3
import os
from datetime import datetime, timedelta
import uuid
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime')

# Environment variables
TABLE_NAME = os.environ['DYNAMODB_TABLE']
BEDROCK_MODEL_ID = os.environ['BEDROCK_MODEL_ID']

table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Enhanced Lex fulfillment function with Generative AI capabilities
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract information from Lex event
        intent_name = event['sessionState']['intent']['name']
        session_attributes = event.get('sessionState', {}).get('sessionAttributes', {})
        
        # Handle different intents
        if intent_name == 'WelcomeIntent':
            return handle_welcome_intent(event)
        elif intent_name == 'MeetingManagement':
            return handle_meeting_management_intent(event)
        else:
            return handle_fallback_intent(event)
            
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(
            event,
            "I apologize, but I encountered an error. Please try again.",
            'Failed'
        )

def handle_welcome_intent(event):
    """Handle welcome and greeting messages"""
    welcome_message = """Hello! I'm Meety, your AI-powered meeting assistant. 

I can help you with:
• Scheduling new meetings
• Checking your upcoming meetings
• Managing meeting status
• Finding available time slots

How can I assist you today?"""
    
    return create_response(event, welcome_message, 'Fulfilled')

def handle_meeting_management_intent(event):
    """Handle meeting-related requests using Generative AI"""
    
    # Get user input
    user_input = event.get('inputTranscript', '')
    session_attributes = event.get('sessionState', {}).get('sessionAttributes', {})
    
    # Use Bedrock to understand the user's intent and extract information
    meeting_info = extract_meeting_info_with_ai(user_input, session_attributes)
    
    if meeting_info.get('action') == 'schedule':
        return handle_schedule_meeting(event, meeting_info)
    elif meeting_info.get('action') == 'check':
        return handle_check_meetings(event, meeting_info)
    elif meeting_info.get('action') == 'update':
        return handle_update_meeting(event, meeting_info)
    else:
        return ask_for_clarification(event, user_input)

def extract_meeting_info_with_ai(user_input, session_attributes):
    """Use Bedrock to extract structured information from natural language"""
    
    prompt = f"""
    You are a meeting scheduling assistant. Analyze the following user request and extract structured information.
    
    User request: "{user_input}"
    Previous context: {json.dumps(session_attributes)}
    
    Please respond with a JSON object containing:
    - action: "schedule", "check", "update", or "unclear"
    - date: extracted date (YYYY-MM-DD format) or null
    - time: extracted time (HH:MM format) or null
    - duration: extracted duration in minutes or null
    - attendee_name: extracted name or null
    - attendee_email: extracted email or null
    - meeting_title: extracted meeting title or null
    - missing_info: array of missing required information
    
    Only return the JSON object, no other text.
    """
    
    try:
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 500,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )
        
        response_body = json.loads(response['body'].read())
        ai_response = response_body['content'][0]['text']
        
        # Parse the JSON response from AI
        return json.loads(ai_response)
        
    except Exception as e:
        logger.error(f"Error calling Bedrock: {str(e)}")
        return {"action": "unclear", "missing_info": ["all"]}

def handle_schedule_meeting(event, meeting_info):
    """Handle meeting scheduling requests"""
    
    missing_info = meeting_info.get('missing_info', [])
    
    if missing_info:
        return ask_for_missing_info(event, missing_info, meeting_info)
    
    # Create meeting in DynamoDB
    meeting_id = str(uuid.uuid4())
    
    try:
        # Check for conflicts
        if check_meeting_conflict(meeting_info['date'], meeting_info['time'], meeting_info.get('duration', 60)):
            return create_response(
                event,
                f"I found a scheduling conflict for {meeting_info['date']} at {meeting_info['time']}. Would you like to try a different time?",
                'ElicitSlot'
            )
        
        # Save meeting to database
        table.put_item(
            Item={
                'meetingId': meeting_id,
                'attendeeName': meeting_info.get('attendee_name', 'Unknown'),
                'email': meeting_info.get('attendee_email', ''),
                'date': meeting_info['date'],
                'startTime': meeting_info['time'],
                'endTime': calculate_end_time(meeting_info['time'], meeting_info.get('duration', 60)),
                'duration': str(meeting_info.get('duration', 60)),
                'title': meeting_info.get('meeting_title', 'Meeting'),
                'status': 'pending',
                'createdAt': datetime.now().isoformat(),
                'isConflict': False
            }
        )
        
        success_message = f"""Perfect! I've scheduled your meeting:

📅 Date: {meeting_info['date']}
🕐 Time: {meeting_info['time']} - {calculate_end_time(meeting_info['time'], meeting_info.get('duration', 60))}
👤 Attendee: {meeting_info.get('attendee_name', 'Unknown')}
📧 Email: {meeting_info.get('attendee_email', 'Not provided')}

Your meeting ID is: {meeting_id[:8]}
Status: Pending confirmation

Is there anything else I can help you with?"""
        
        return create_response(event, success_message, 'Fulfilled')
        
    except Exception as e:
        logger.error(f"Error creating meeting: {str(e)}")
        return create_response(
            event,
            "I encountered an error while scheduling your meeting. Please try again.",
            'Failed'
        )

def handle_check_meetings(event, meeting_info):
    """Handle requests to check existing meetings"""
    
    try:
        # Query meetings based on date range or status
        if meeting_info.get('date'):
            # Check meetings for specific date
            response = table.query(
                IndexName='StatusIndex',
                KeyConditionExpression='#status = :status AND #date = :date',
                ExpressionAttributeNames={
                    '#status': 'status',
                    '#date': 'date'
                },
                ExpressionAttributeValues={
                    ':status': 'approved',
                    ':date': meeting_info['date']
                }
            )
        else:
            # Check pending meetings
            response = table.query(
                IndexName='StatusIndex',
                KeyConditionExpression='#status = :status',
                ExpressionAttributeNames={
                    '#status': 'status'
                },
                ExpressionAttributeValues={
                    ':status': 'pending'
                }
            )
        
        meetings = response['Items']
        
        if not meetings:
            message = "You don't have any meetings scheduled for the requested time period."
        else:
            message = format_meetings_list(meetings)
        
        return create_response(event, message, 'Fulfilled')
        
    except Exception as e:
        logger.error(f"Error checking meetings: {str(e)}")
        return create_response(
            event,
            "I encountered an error while checking your meetings. Please try again.",
            'Failed'
        )

def ask_for_missing_info(event, missing_info, current_info):
    """Ask user for missing information"""
    
    questions = {
        'date': "What date would you like to schedule the meeting?",
        'time': "What time works best for you?",
        'duration': "How long should the meeting be? (in minutes)",
        'attendee_name': "What's the name of the person you're meeting with?",
        'attendee_email': "What's their email address?",
        'meeting_title': "What would you like to call this meeting?"
    }
    
    # Ask for the first missing piece of information
    first_missing = missing_info[0]
    question = questions.get(first_missing, "Could you provide more details about your meeting?")
    
    # Store current information in session attributes
    session_attributes = {
        'meeting_info': json.dumps(current_info),
        'asking_for': first_missing
    }
    
    return create_response(event, question, 'ElicitSlot', session_attributes)

def ask_for_clarification(event, user_input):
    """Ask for clarification when intent is unclear"""
    
    clarification_message = f"""I want to make sure I understand correctly. It sounds like you want help with meetings, but I need a bit more information.

Are you looking to:
• Schedule a new meeting
• Check your existing meetings
• Update or cancel a meeting

Could you please clarify what you'd like to do?"""
    
    return create_response(event, clarification_message, 'ElicitIntent')

def check_meeting_conflict(date, time, duration):
    """Check if there's a scheduling conflict"""
    
    try:
        end_time = calculate_end_time(time, duration)
        
        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status AND #date = :date',
            FilterExpression='(#start_time <= :end_time AND #end_time >= :start_time)',
            ExpressionAttributeNames={
                '#status': 'status',
                '#date': 'date',
                '#start_time': 'startTime',
                '#end_time': 'endTime'
            },
            ExpressionAttributeValues={
                ':status': 'approved',
                ':date': date,
                ':start_time': time,
                ':end_time': end_time
            }
        )
        
        return len(response['Items']) > 0
        
    except Exception as e:
        logger.error(f"Error checking conflicts: {str(e)}")
        return False

def calculate_end_time(start_time, duration_minutes):
    """Calculate end time based on start time and duration"""
    
    start_dt = datetime.strptime(start_time, '%H:%M')
    end_dt = start_dt + timedelta(minutes=duration_minutes)
    return end_dt.strftime('%H:%M')

def format_meetings_list(meetings):
    """Format meetings list for display"""
    
    if not meetings:
        return "No meetings found."
    
    message = "Here are your meetings:\n\n"
    
    for meeting in meetings[:5]:  # Limit to 5 meetings
        message += f"📅 {meeting.get('date', 'Unknown date')}\n"
        message += f"🕐 {meeting.get('startTime', 'Unknown time')} - {meeting.get('endTime', 'Unknown end')}\n"
        message += f"👤 {meeting.get('attendeeName', 'Unknown attendee')}\n"
        message += f"📋 Status: {meeting.get('status', 'Unknown').title()}\n\n"
    
    if len(meetings) > 5:
        message += f"... and {len(meetings) - 5} more meetings."
    
    return message

def create_response(event, message, dialog_action, session_attributes=None):
    """Create a properly formatted Lex response"""
    
    if session_attributes is None:
        session_attributes = event.get('sessionState', {}).get('sessionAttributes', {})
    
    response = {
        'sessionState': {
            'dialogAction': {
                'type': dialog_action
            },
            'intent': event['sessionState']['intent'],
            'sessionAttributes': session_attributes
        },
        'messages': [
            {
                'contentType': 'PlainText',
                'content': message
            }
        ]
    }
    
    return response

def handle_fallback_intent(event):
    """Handle unrecognized intents"""
    
    fallback_message = """I'm not sure I understand what you're asking for. I'm specialized in helping with meeting management.

I can help you:
• Schedule new meetings
• Check your existing meetings  
• Update meeting details

Could you please rephrase your request?"""
    
    return create_response(event, fallback_message, 'ElicitIntent')