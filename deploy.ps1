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

# Step 2: Configure Lex intents and slots
Write-Host "Step 2: Configuring Lex intents and slots..."
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "configure-lex-intents-fixed.ps1"
& $scriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lex intent configuration failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Step 3: Create Lex bot alias
Write-Host "Step 3: Creating Lex bot alias..."
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "create-lex-alias.ps1"
& $scriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lex bot alias creation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Step 4: Update configuration files
Write-Host "Step 4: Updating configuration files..."
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "update-config.ps1"
& $scriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Configuration update failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Step 5: Deploy frontend to S3
Write-Host "Step 5: Deploying frontend to S3..."

# Get the S3 bucket name from Terraform outputs
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json
$cloudFrontUrl = $outputs.cloudfront_distribution_url.value
$s3BucketName = $outputs.s3_bucket_name.value

Write-Host "CloudFront URL: $cloudFrontUrl"
Write-Host "S3 Bucket Name: $s3BucketName"

# Check if the S3 bucket exists
Write-Host "Checking if S3 bucket exists: $s3BucketName"
$bucketExists = $false
try {
    $bucketCheck = aws --no-cli-pager s3api head-bucket --bucket $s3BucketName 2>&1
    $bucketExists = $true
    Write-Host "S3 bucket exists: $s3BucketName"
} catch {
    Write-Host "S3 bucket does not exist or is not accessible: $s3BucketName"
    Write-Host "Error: $_"
}

if ($bucketExists) {
    Write-Host "Deploying frontend to S3 bucket: $s3BucketName"
    aws --no-cli-pager s3 sync frontend/ s3://$s3BucketName/ --delete

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Frontend deployment failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host "Skipping frontend deployment as S3 bucket does not exist or is not accessible."
    Write-Host "Please check the S3 bucket configuration in Terraform."
}

# Step 6: Invalidate CloudFront cache
Write-Host "Step 6: Invalidating CloudFront cache..."
$distributionId = $outputs.cloudfront_distribution_id.value

if ($distributionId) {
    Write-Host "CloudFront Distribution ID: $distributionId"
    aws --no-cli-pager cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CloudFront invalidation failed with exit code $LASTEXITCODE"
        Write-Host "This is non-critical, continuing deployment..."
    } else {
        Write-Host "CloudFront invalidation created successfully"
    }
} else {
    Write-Host "CloudFront Distribution ID not found in Terraform outputs, skipping cache invalidation"
}

Write-Host "Deployment completed successfully!"
Write-Host "You can access the application at: https://$cloudFrontUrl"
Write-Host "Note: It may take a few minutes for CloudFront to distribute your content globally"