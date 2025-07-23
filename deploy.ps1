# PowerShell script to deploy the entire application

# Step 1: Deploy infrastructure with Terraform
Write-Host "Step 1: Deploying infrastructure with Terraform..."
Push-Location -Path IaC
try {
    # Initialize Terraform
    Write-Host "Initializing Terraform..."
    terraform init

    # Apply Terraform configuration
    Write-Host "Applying Terraform configuration..."
    terraform apply -auto-approve

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform apply failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

# Step 2: Create Lex bot alias
Write-Host "Step 2: Creating Lex bot alias..."
./create-lex-alias.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lex bot alias creation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Step 3: Deploy frontend to S3
Write-Host "Step 3: Deploying frontend to S3..."

# Get the S3 bucket name from Terraform outputs
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json
$cloudFrontUrl = $outputs.cloudfront_distribution_url.value

# Get the S3 bucket name from the CloudFront distribution
$s3BucketName = aws cloudfront get-distribution --id $(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='$cloudFrontUrl'].Id" --output text) --query "Distribution.DistributionConfig.Origins.Items[0].DomainName" --output text
$s3BucketName = $s3BucketName -replace "\.s3\.amazonaws\.com", ""

Write-Host "Deploying frontend to S3 bucket: $s3BucketName"
aws s3 sync frontend/ s3://$s3BucketName/ --delete

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend deployment failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Deployment completed successfully!"
Write-Host "You can access the application at: https://$cloudFrontUrl"