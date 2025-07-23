# PowerShell script to update configuration files with actual IDs
param (
    [string]$botAliasId = ""
)

# Get the Terraform outputs
Write-Host "Getting Terraform outputs..."
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json

# Extract the values
$lexBotId = $outputs.lex_bot_id.value
$cognitoIdentityPoolId = $outputs.cognito_identity_pool_id.value
$cognitoUserPoolId = $outputs.cognito_user_pool_id.value
$cognitoClientId = $outputs.cognito_client_id.value
$apiUrl = $outputs.api_url.value

Write-Host "Found the following IDs:"
Write-Host "Lex Bot ID: $lexBotId"
Write-Host "Cognito Identity Pool ID: $cognitoIdentityPoolId"
Write-Host "Cognito User Pool ID: $cognitoUserPoolId"
Write-Host "Cognito Client ID: $cognitoClientId"
Write-Host "API URL: $apiUrl"

# Get the Bot Alias ID - either from parameter or prompt the user
$lexBotAliasId = $botAliasId
if ([string]::IsNullOrEmpty($lexBotAliasId)) {
    $lexBotAliasId = Read-Host -Prompt "Enter the Lex Bot Alias ID"
}
Write-Host "Using Bot Alias ID: $lexBotAliasId"

# Update the frontend/index.html file
Write-Host "Updating frontend/index.html..."
$htmlContent = Get-Content -Path frontend/index.html -Raw

# Update Lex configuration
$htmlContent = $htmlContent -replace 'botId: "XXXXXXXXXX"', "botId: `"$lexBotId`""
$htmlContent = $htmlContent -replace 'botId: "[A-Z0-9]+"', "botId: `"$lexBotId`""
$htmlContent = $htmlContent -replace 'botAliasId: "XXXXXXXXXX"', "botAliasId: `"$lexBotAliasId`""
$htmlContent = $htmlContent -replace 'botAliasId: "[A-Z0-9]+"', "botAliasId: `"$lexBotAliasId`""
$htmlContent = $htmlContent -replace 'identityPoolId: "us-east-1:XXXXXXXXXX"', "identityPoolId: `"$cognitoIdentityPoolId`""
$htmlContent = $htmlContent -replace 'identityPoolId: "us-east-1:[a-z0-9-]+"', "identityPoolId: `"$cognitoIdentityPoolId`""
$htmlContent = $htmlContent -replace "IdentityPoolId: 'us-east-1:XXXXXXXXXX'", "IdentityPoolId: '$cognitoIdentityPoolId'"
$htmlContent = $htmlContent -replace "IdentityPoolId: 'us-east-1:[a-z0-9-]+'", "IdentityPoolId: '$cognitoIdentityPoolId'"

# Update Cognito configuration
$htmlContent = $htmlContent -replace 'userPoolId: "us-east-1_[A-Za-z0-9]+"', "userPoolId: `"$cognitoUserPoolId`""
$htmlContent = $htmlContent -replace 'userPoolWebClientId: "[a-z0-9]+"', "userPoolWebClientId: `"$cognitoClientId`""

# Update API Gateway endpoint
$htmlContent = $htmlContent -replace 'endpoint: "https://[a-z0-9]+\.execute-api\.us-east-1\.amazonaws\.com/dev"', "endpoint: `"$apiUrl`""

Set-Content -Path frontend/index.html -Value $htmlContent

# Update the IaC/variables.tf file
Write-Host "Updating IaC/variables.tf..."
$variablesContent = Get-Content -Path IaC/variables.tf -Raw
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot ID', "default     = `"$lexBotId`" # Actual Bot ID"
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot Alias ID', "default     = `"$lexBotAliasId`" # Actual Bot Alias ID"
Set-Content -Path IaC/variables.tf -Value $variablesContent

Write-Host "Configuration files updated successfully!"
Write-Host "You can now deploy the frontend to S3."