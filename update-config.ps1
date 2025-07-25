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

# Update the frontend/assets/index-direct-lex.js file
Write-Host "Updating frontend/assets/index-direct-lex.js..."
$jsContent = Get-Content -Path frontend/assets/index-direct-lex.js -Raw

# Update Lex configuration
$jsContent = $jsContent -replace 'botId: "XXXXXXXXXX"', "botId: `"$lexBotId`""
$jsContent = $jsContent -replace 'botId: "[A-Z0-9]+"', "botId: `"$lexBotId`""
$jsContent = $jsContent -replace 'botAliasId: "XXXXXXXXXX"', "botAliasId: `"$lexBotAliasId`""
$jsContent = $jsContent -replace 'botAliasId: "[A-Z0-9]+"', "botAliasId: `"$lexBotAliasId`""
$jsContent = $jsContent -replace 'identityPoolId: "us-east-1:XXXXXXXXXX"', "identityPoolId: `"$cognitoIdentityPoolId`""
$jsContent = $jsContent -replace 'identityPoolId: "us-east-1:[a-z0-9-]+"', "identityPoolId: `"$cognitoIdentityPoolId`""

# Update Cognito configuration
$jsContent = $jsContent -replace 'userPoolId: "us-east-1_[A-Za-z0-9]+"', "userPoolId: `"$cognitoUserPoolId`""
$jsContent = $jsContent -replace 'userPoolWebClientId: "[a-z0-9]+"', "userPoolWebClientId: `"$cognitoClientId`""

# Update API Gateway endpoint
$jsContent = $jsContent -replace 'endpoint: "https://[a-z0-9]+\.execute-api\.us-east-1\.amazonaws\.com/dev"', "endpoint: `"$apiUrl`""

Set-Content -Path frontend/assets/index-direct-lex.js -Value $jsContent

# Update the IaC/variables.tf file
Write-Host "Updating IaC/variables.tf..."
$variablesContent = Get-Content -Path IaC/variables.tf -Raw
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot ID', "default     = `"$lexBotId`" # Actual Bot ID"
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot Alias ID', "default     = `"$lexBotAliasId`" # Actual Bot Alias ID"
Set-Content -Path IaC/variables.tf -Value $variablesContent

Write-Host "Configuration files updated successfully!"
Write-Host "You can now deploy the frontend to S3."