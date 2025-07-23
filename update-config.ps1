# PowerShell script to update configuration files with actual IDs

# Get the Terraform outputs
Write-Host "Getting Terraform outputs..."
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json

# Extract the values
$lexBotId = $outputs.lex_bot_id.value
$cognitoIdentityPoolId = $outputs.cognito_identity_pool_id.value

Write-Host "Found the following IDs:"
Write-Host "Lex Bot ID: $lexBotId"
Write-Host "Cognito Identity Pool ID: $cognitoIdentityPoolId"

# Prompt for the manually created Bot Alias ID
$lexBotAliasId = Read-Host -Prompt "Enter the manually created Lex Bot Alias ID"

# Update the frontend/index.html file
Write-Host "Updating frontend/index.html..."
$htmlContent = Get-Content -Path frontend/index.html -Raw
$htmlContent = $htmlContent -replace 'botId: "XXXXXXXXXX"', "botId: `"$lexBotId`""
$htmlContent = $htmlContent -replace 'botAliasId: "XXXXXXXXXX"', "botAliasId: `"$lexBotAliasId`""
$htmlContent = $htmlContent -replace 'identityPoolId: "us-east-1:XXXXXXXXXX"', "identityPoolId: `"$cognitoIdentityPoolId`""
$htmlContent = $htmlContent -replace "IdentityPoolId: 'us-east-1:XXXXXXXXXX'", "IdentityPoolId: '$cognitoIdentityPoolId'"
Set-Content -Path frontend/index.html -Value $htmlContent

# Update the IaC/variables.tf file
Write-Host "Updating IaC/variables.tf..."
$variablesContent = Get-Content -Path IaC/variables.tf -Raw
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot ID', "default     = `"$lexBotId`" # Actual Bot ID"
$variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot Alias ID', "default     = `"$lexBotAliasId`" # Actual Bot Alias ID"
Set-Content -Path IaC/variables.tf -Value $variablesContent

Write-Host "Configuration files updated successfully!"
Write-Host "You can now deploy the frontend to S3."