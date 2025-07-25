# Meety - AI-powered Meeting Management

Meety is a meeting management chatbot application that helps users manage and track meetings through conversational AI powered by Amazon Lex V2 and Amazon Bedrock.

## Architecture

The application uses the following AWS services:

- **Amazon Cognito**: User authentication and authorization
- **Amazon Lex V2**: Conversational AI chatbot with generative capabilities
- **Amazon Bedrock**: Generative AI foundation models
- **Amazon DynamoDB**: NoSQL database for meeting data
- **Amazon S3**: Static website hosting
- **Amazon CloudFront**: CDN for frontend distribution
- **Amazon API Gateway**: HTTP API for backend services
- **AWS Lambda**: Serverless compute for backend logic

## Project Structure

```
├── frontend/                # Static web frontend
│   ├── assets/              # JavaScript, CSS, and image files
│   └── index.html           # Main HTML entry point
├── IaC/                     # Infrastructure as Code (Terraform)
│   ├── lambda/              # Lambda function source code
│   ├── *.tf                 # Terraform configuration files
│   └── LEX-INTENT-CONFIG.md # Detailed Lex intent configuration
├── *.ps1                    # PowerShell deployment scripts
└── README.md                # This file
```

## Deployment Instructions

### Option 1: Automated Deployment (Recommended)

You can use the master deployment script to deploy the entire application in one step:

```powershell
# Run from the project root directory
./deploy.ps1
```

This script will:
1. Deploy the infrastructure with Terraform
2. Configure Lex intents, slots, and responses automatically (configure-lex-intents.ps1)
3. Create the Lex bot alias automatically (create-lex-alias.ps1)
4. Update all configuration files with the actual AWS resource IDs (update-config.ps1)
5. Deploy the frontend to S3

### Option 2: Manual Deployment

If you prefer to deploy the application step by step:

#### 1. Deploy Infrastructure

```bash
cd IaC
terraform init
terraform apply
```

After the infrastructure is deployed, you'll see the outputs including the Lex bot ID, Cognito IDs, and API Gateway URL.

### 2. Configuration Steps

After applying Terraform, you can configure the Lex bot automatically or manually:

#### Option 1: Automated Lex Configuration (Recommended)

Run the provided PowerShell scripts to automatically configure the Lex bot:

```powershell
# Configure Lex intents, slots, and responses
./configure-lex-intents.ps1

# Create the Lex bot alias
./create-lex-alias.ps1
```

These scripts will:
1. Configure the StartMeety intent with appropriate responses
2. Configure the MeetingAssistant intent with slots and responses
3. Configure the FallbackIntent with appropriate responses
4. Create a "prod" alias for the bot
5. Update all configuration files automatically

#### Option 2: Manual Lex Configuration

If you prefer to configure the Lex bot manually:

1. Go to the AWS Console > Amazon Lex > Bots > MeetyGenerativeBot
2. Configure the StartMeety intent with appropriate responses
3. Configure the MeetingAssistant intent with slots and responses
4. Configure the FallbackIntent with appropriate responses
5. Create a "prod" alias for the bot
6. Run the update-config.ps1 script to update configuration files

For detailed instructions on manual configuration, see [LEX-INTENT-CONFIG.md](IaC/LEX-INTENT-CONFIG.md).

#### Update Configuration Files

The `update-config.ps1` script is automatically called by the `create-lex-alias.ps1` script, so you don't need to run it separately:

After creating the resources, you can use the provided PowerShell script to update the configuration files:

```powershell
# Run from the project root directory
./update-config.ps1
```

The script will:
1. Get the Terraform outputs:
   - Lex Bot ID
   - Cognito Identity Pool ID
   - Cognito User Pool ID
   - Cognito User Pool Web Client ID
   - API Gateway endpoint URL
2. Prompt you for the manually created Bot Alias ID
3. Update the following files with the actual IDs:
   - `frontend/index.html` - All AWS resource IDs and endpoints
   - `IaC/variables.tf` - Lex Bot ID and Bot Alias ID

Alternatively, you can manually update the following files:

1. Update `frontend/assets/index-direct-lex.js`:
   - Replace the `botId` field with the actual MeetyGenerativeBot ID
   - Replace the `botAliasId` field with the manually created "prod" alias ID
   - Replace the `identityPoolId` field with the actual Cognito Identity Pool ID
   - Replace the `userPoolId` field with the actual Cognito User Pool ID
   - Replace the `userPoolWebClientId` field with the actual Cognito User Pool Web Client ID
   - Replace the API Gateway `endpoint` field with the actual API Gateway URL

2. Update `IaC/variables.tf`:
   - Update `lex_bot_id` with the actual MeetyGenerativeBot ID
   - Update `lex_bot_alias_id` with the manually created "prod" alias ID

### 3. Deploy Frontend

Upload the frontend files to the S3 bucket:

```bash
# Get the S3 bucket name from Terraform outputs
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json
$s3BucketName = $outputs.s3_bucket_name.value

# Deploy to S3
aws s3 sync frontend/ s3://$s3BucketName/ --delete
```

## Usage

1. Access the application through the CloudFront URL provided in the Terraform output
2. Use the chatbot interface to manage meetings through natural language
3. Sign in to the admin panel to view and manage meetings

### Testing the Bot

After deployment, you can test the bot:

1. Access the application through the CloudFront URL
2. In the chatbot interface, try the following:
   - Type "Hello" or "Hi" to test the StartMeety intent
   - Type "I want to schedule a meeting" to test the MeetingAssistant intent
   - Follow the prompts to provide the required information
   - Confirm the meeting when prompted
3. The meeting will be saved to the DynamoDB table

### Troubleshooting

If you encounter any issues:

1. Check the CloudWatch logs for the Lambda functions
2. Ensure all slots are properly configured
3. Verify that the Lambda functions have the correct permissions
4. Check the browser console for any frontend errors

## Features

- Meeting scheduling and status management
- AI-powered chatbot interface using Amazon Lex with generative capabilities
- User authentication and authorization
- Meeting status tracking (pending, confirmed, etc.)
- Web-based frontend interface

## Architecture Diagram

```
┌─────────────┐     ┌───────────────┐     ┌───────────────┐
│             │     │               │     │               │
│  Frontend   │────▶│  Amazon       │────▶│  Amazon       │
│  (React)    │     │  Cognito      │     │  Lex V2       │
│             │     │               │     │               │
└─────────────┘     └───────────────┘     └───────┬───────┘
                                                  │
                                                  ▼
                                          ┌───────────────┐
                                          │               │
                                          │  Amazon       │
                                          │  Bedrock      │
                                          │               │
                                          └───────────────┘
```

## Direct Lex Integration

This application uses direct integration between the frontend and Amazon Lex V2 using the AWS SDK, eliminating the need for API Gateway and Lambda intermediaries for the chatbot functionality. This approach:

1. Eliminates CORS issues
2. Reduces latency
3. Simplifies the architecture

### Authentication Approach

The application supports two authentication modes for Lex access:

1. **Anonymous Access**: Users can interact with the chatbot without signing in. This uses the Cognito Identity Pool's unauthenticated role.

2. **Authenticated Access**: When users sign in through the Admin panel, they get additional permissions through the Cognito Identity Pool's authenticated role.

This dual-mode approach ensures that:
- All users can use the chatbot functionality
- Authenticated users get additional permissions for admin functions

### Removing API Gateway Resources

If you want to completely remove the API Gateway and Lambda resources for the chatbot (since they're no longer needed with direct Lex integration), you can use the provided cleanup script:

```powershell
# Run from the project root directory
./cleanup-api-gateway.ps1
```

This script will:
1. Remove the generative_chatbot route and integration from apigateway.tf
2. Remove the generative_chatbot Lambda function from lambda-generative.tf
3. Remove the generative_chatbot.py and generative_chatbot.zip files

After running the script, you'll need to run `terraform apply` to apply these changes.