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

### Option 1: Automated Deployment (Recommended)

You can use the master deployment script to deploy the entire application in one step:

```powershell
# Run from the project root directory
./deploy.ps1
```

This script will:
1. Deploy the infrastructure with Terraform
2. Create the Lex bot alias automatically
3. Update all configuration files
4. Deploy the frontend to S3

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

After applying Terraform, you can either create the Lex bot alias automatically or manually:

#### Option 1: Automated Bot Alias Creation (Recommended)

Run the provided PowerShell script to automatically create the Lex bot alias:

```powershell
# Run from the project root directory
./create-lex-alias.ps1
```

This script will:
1. Get the Lex bot ID from Terraform outputs
2. Find the latest bot version
3. Create a "prod" alias for the bot
4. Update all configuration files automatically

#### Option 2: Manual Bot Alias Creation

If you prefer to create the bot alias manually:

1. Go to the AWS Console > Amazon Lex > Bots > MeetyGenerativeBot
2. Go to the Aliases tab and create a new alias named "prod"
3. Associate it with the version created by Terraform
4. Enable the generative AI features in the console
5. Run the update-config.ps1 script to update configuration files

#### Update Configuration Files

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

1. Update `frontend/index.html`:
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
# Get the S3 bucket name from the CloudFront distribution
$cloudFrontUrl = terraform -chdir=IaC output -json | ConvertFrom-Json | Select-Object -ExpandProperty cloudfront_distribution_url | Select-Object -ExpandProperty value
$s3BucketName = aws cloudfront get-distribution --id $(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$cloudFrontUrl'].Id" --output text) --query "Distribution.DistributionConfig.Origins.Items[0].DomainName" --output text
$s3BucketName = $s3BucketName -replace "\.s3\.amazonaws\.com", ""

# Deploy to S3
aws s3 sync frontend/ s3://$s3BucketName/ --delete
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