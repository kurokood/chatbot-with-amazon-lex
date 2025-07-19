# Meety - AI-Powered Meeting Assistant

Meety is a meeting management chatbot application that helps users manage and track meetings through conversational AI powered by Amazon Lex and AWS services.

## Architecture

This application uses the following AWS services:

- **Amazon Lex v2** - Conversational AI chatbot
- **AWS Lambda** - Serverless compute for backend logic
- **Amazon API Gateway** - HTTP API for frontend-backend communication
- **Amazon DynamoDB** - NoSQL database for meeting data
- **Amazon Cognito** - User authentication and authorization
- **Amazon S3** - Static website hosting
- **Amazon CloudFront** - CDN for frontend distribution
- **Amazon Route53** - DNS management

## Features

- Meeting scheduling through natural language conversations
- Meeting status tracking (pending, confirmed, etc.)
- User authentication and authorization
- Web-based frontend interface

## Deployment Instructions

### Prerequisites

1. AWS CLI installed and configured
2. Terraform installed
3. Node.js and npm installed (for frontend development)

### Deploying the Infrastructure

1. Navigate to the IaC directory:
   ```
   cd IaC
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the Terraform configuration:
   ```
   terraform apply
   ```

4. Follow the manual configuration steps in the IaC/README.md file to complete the setup.

### Deploying the Frontend

1. Update the frontend configuration with the API endpoint and Cognito user pool details:
   ```
   cd frontend
   ```

2. Build and deploy the frontend:
   ```
   npm install
   npm run build
   ```

3. Upload the build artifacts to the S3 bucket:
   ```
   aws s3 sync build/ s3://YOUR_S3_BUCKET_NAME --delete
   ```

4. Create a CloudFront invalidation to update the CDN:
   ```
   aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
   ```

## Using the Chatbot

1. Open the frontend application in your browser
2. Sign in with your Cognito credentials
3. Use the chatbot to schedule meetings with natural language:
   - "I want to schedule a meeting"
   - "Book a meeting with John tomorrow at 2pm"
   - "Schedule a call with Sarah on Friday"

4. The chatbot will guide you through the process of scheduling a meeting, asking for any missing information.

## Development

### Local Development

1. Clone the repository
2. Install dependencies:
   ```
   cd frontend
   npm install
   ```

3. Start the development server:
   ```
   npm start
   ```

### Updating the Lambda Functions

1. Edit the Lambda function code in the `IaC/lambda` directory
2. Package the Lambda function:
   ```
   cd IaC
   zip -j lambda/function_name.zip lambda/function_name.py
   ```

3. Apply the changes with Terraform:
   ```
   terraform apply
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.