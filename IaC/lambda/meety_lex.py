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

# Environment variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'Meetings')

table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Lambda function for handling Lex intents
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract intent name and state
        intent_name = event['sessionState']['intent']['name']
        intent_state = event['sessionState']['intent'].get('state', '')
        confirmation_state = event['sessionState']['intent'].get('confirmationState', '')
        slots = event['sessionState']['intent'].get('slots', {})
        
        logger.info(f"Intent name: {intent_name}")
        logger.info(f"Intent state: {intent_state}")
        logger.info(f"Confirmation state: {confirmation_state}")
        logger.info(f"Slots: {json.dumps(slots)}")
        
        # Handle StartMeety intent
        if intent_name == 'StartMeety':
            # Just delegate to Lex to use the conclusion statement
            return {
                'sessionState': {
                    'dialogAction': {
                        'type': 'Close'
                    },
                    'intent': {
                        'name': intent_name,
                        'state': 'Fulfilled'
                    }
                }
            }
        
        # Handle FallbackIntent
        if intent_name == 'FallbackIntent':
            # Just delegate to Lex to use the conclusion statement
            return {
                'sessionState': {
                    'dialogAction': {
                        'type': 'Close'
                    },
                    'intent': {
                        'name': intent_name,
                        'state': 'Fulfilled'
                    }
                }
            }
        
        # Handle MeetingAssistant intent
        if intent_name == 'MeetingAssistant':
            # Check if all required slots are filled
            required_slots = ['date', 'time', 'attendeeName', 'meetingTitle']
            all_slots_filled = True
            
            for slot_name in required_slots:
                if not slots.get(slot_name) or not slots[slot_name].get('value') or not slots[slot_name]['value'].get('interpretedValue'):
                    all_slots_filled = False
                    break
            
            # If confirmation is needed
            if all_slots_filled and confirmation_state == 'None':
                # Let Lex handle the confirmation
                return {
                    'sessionState': {
                        'dialogAction': {
                            'type': 'Delegate'
                        }
                    }
                }
            
            # If confirmed, schedule the meeting
            elif confirmation_state == 'Confirmed':
                # Extract meeting info from slots
                meeting_info = {}
                
                # Extract date
                if slots.get('date') and slots['date'].get('value') and slots['date']['value'].get('interpretedValue'):
                    meeting_info['date'] = slots['date']['value']['interpretedValue']
                
                # Extract time
                if slots.get('time') and slots['time'].get('value') and slots['time']['value'].get('interpretedValue'):
                    meeting_info['time'] = slots['time']['value']['interpretedValue']
                
                # Extract attendee name
                if slots.get('attendeeName') and slots['attendeeName'].get('value') and slots['attendeeName']['value'].get('interpretedValue'):
                    meeting_info['attendee_name'] = slots['attendeeName']['value']['interpretedValue']
                
                # Extract meeting title
                if slots.get('meetingTitle') and slots['meetingTitle'].get('value') and slots['meetingTitle']['value'].get('interpretedValue'):
                    meeting_info['meeting_title'] = slots['meetingTitle']['value']['interpretedValue']
                
                # Schedule the meeting
                try:
                    # Generate a unique ID for the meeting
                    meeting_id = str(uuid.uuid4())
                    
                    # Parse the date and time
                    date = meeting_info.get('date', datetime.now().strftime('%Y-%m-%d'))
                    time = meeting_info.get('time', '09:00')
                    
                    # Calculate end time (default to 1 hour)
                    start_time = time
                    end_time = calculate_end_time(start_time, 60)
                    
                    # Save to DynamoDB
                    item = {
                        'meetingId': meeting_id,
                        'attendeeName': meeting_info.get('attendee_name', 'Unknown'),
                        'date': date,
                        'startTime': start_time,
                        'endTime': end_time,
                        'title': meeting_info.get('meeting_title', 'Meeting'),
                        'status': 'pending',
                        'createdAt': datetime.now().isoformat()
                    }
                    
                    # Log the item we're saving
                    logger.info(f"Saving meeting to DynamoDB: {json.dumps(item)}")
                    
                    # Save to DynamoDB
                    table.put_item(Item=item)
                    
                    # Format the date and time for display
                    try:
                        parsed_date = datetime.strptime(date, '%Y-%m-%d')
                        formatted_date = parsed_date.strftime('%A, %B %d, %Y')
                    except:
                        formatted_date = date
                    
                    # Create a confirmation message
                    confirmation = f"""Perfect! I've scheduled your meeting:

📅 Date: {formatted_date}
🕐 Time: {time}
👤 Attendee: {meeting_info.get('attendee_name', 'Unknown')}
📋 Title: {meeting_info.get('meeting_title', 'Meeting')}

Your meeting has been scheduled successfully!"""
                    
                    # Return a fulfilled response
                    return {
                        'sessionState': {
                            'dialogAction': {
                                'type': 'Close'
                            },
                            'intent': {
                                'name': intent_name,
                                'state': 'Fulfilled'
                            }
                        },
                        'messages': [
                            {
                                'contentType': 'PlainText',
                                'content': confirmation
                            }
                        ]
                    }
                    
                except Exception as e:
                    logger.error(f"Error scheduling meeting: {str(e)}")
                    return {
                        'sessionState': {
                            'dialogAction': {
                                'type': 'Close'
                            },
                            'intent': {
                                'name': intent_name,
                                'state': 'Failed'
                            }
                        },
                        'messages': [
                            {
                                'contentType': 'PlainText',
                                'content': f"I'm sorry, I couldn't schedule your meeting: {str(e)}"
                            }
                        ]
                    }
            
            # If denied, cancel the meeting
            elif confirmation_state == 'Denied':
                return {
                    'sessionState': {
                        'dialogAction': {
                            'type': 'Close'
                        },
                        'intent': {
                            'name': intent_name,
                            'state': 'Failed'
                        }
                    },
                    'messages': [
                        {
                            'contentType': 'PlainText',
                            'content': "I've cancelled the meeting request. Is there anything else I can help you with?"
                        }
                    ]
                }
            
            # For all other cases, delegate to Lex
            return {
                'sessionState': {
                    'dialogAction': {
                        'type': 'Delegate'
                    }
                }
            }
        
        # For any other intent, delegate to Lex
        return {
            'sessionState': {
                'dialogAction': {
                    'type': 'Delegate'
                }
            }
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'sessionState': {
                'dialogAction': {
                    'type': 'Close'
                },
                'intent': {
                    'name': event['sessionState']['intent']['name'],
                    'state': 'Failed'
                }
            },
            'messages': [
                {
                    'contentType': 'PlainText',
                    'content': f"I'm sorry, I encountered an error: {str(e)}"
                }
            ]
        }

def calculate_end_time(start_time, duration_minutes):
    """Calculate end time based on start time and duration"""
    try:
        # Handle simple time formats like "9am" or "3pm"
        if 'am' in start_time.lower() or 'pm' in start_time.lower():
            if 'am' in start_time.lower():
                hour = int(start_time.lower().replace('am', '').strip())
                if hour == 12:
                    hour = 0
                start_time = f"{hour:02d}:00"
            else:  # pm
                hour = int(start_time.lower().replace('pm', '').strip())
                if hour < 12:
                    hour += 12
                start_time = f"{hour:02d}:00"
        
        # Try to parse the time
        if ':' not in start_time:
            start_time = f"{start_time}:00"
        
        # Parse the time
        hour, minute = map(int, start_time.split(':'))
        
        # Create a datetime object for today with the given time
        start_dt = datetime.now().replace(hour=hour, minute=minute, second=0, microsecond=0)
        
        # Add the duration
        end_dt = start_dt + timedelta(minutes=duration_minutes)
        
        # Return the end time as a string
        return end_dt.strftime('%H:%M')
    except Exception as e:
        logger.error(f"Error calculating end time: {str(e)}")
        return "Unknown"