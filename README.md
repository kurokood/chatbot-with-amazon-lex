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

## Deployment Instructions

### 1. Deploy Infrastructure

```bash
cd IaC
terraform init
terraform apply
```

### 2. Manual Configuration Steps

After applying Terraform, you need to perform some manual steps in the AWS Console:

#### Create Lex Bot Alias

1. Go to the AWS Console > Amazon Lex > Bots > MeetyGenerativeBot
2. Go to the Aliases tab and create a new alias named "prod"
3. Associate it with the version created by Terraform
4. Enable the generative AI features in the console

#### Update Configuration Files

After creating the resources, you can use the provided PowerShell script to update the configuration files:

```powershell
# Run from the project root directory
./update-config.ps1
```

The script will:
1. Get the Terraform outputs (Lex Bot ID, Cognito Identity Pool ID)
2. Prompt you for the manually created Bot Alias ID
3. Update the following files with the actual IDs:
   - `frontend/index.html`
   - `IaC/variables.tf`

Alternatively, you can manually update the following files:

1. Update `frontend/index.html`:
   - Replace `XXXXXXXXXX` in the `botId` field with the actual MeetyGenerativeBot ID
   - Replace `XXXXXXXXXX` in the `botAliasId` field with the manually created "prod" alias ID
   - Replace `us-east-1:XXXXXXXXXX` in the `IdentityPoolId` field with the actual Cognito Identity Pool ID

2. Update `IaC/variables.tf`:
   - Update `lex_bot_id` with the actual MeetyGenerativeBot ID
   - Update `lex_bot_alias_id` with the manually created "prod" alias ID

### 3. Deploy Frontend

Upload the frontend files to the S3 bucket:

```bash
aws s3 sync frontend/ s3://your-bucket-name/ --delete
```

## Usage

1. Access the application through the CloudFront URL provided in the Terraform output
2. Use the chatbot interface to manage meetings through natural language
3. Sign in to the admin panel to view and manage meetings

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

The frontend authenticates with Amazon Cognito and uses the credentials to directly access Amazon Lex V2 through the AWS SDK.

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