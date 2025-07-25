# PowerShell script to create a Lex bot alias using AWS CLI
# This script automates the manual step of creating a Lex bot alias

# Get the Terraform outputs
Write-Host "Getting Terraform outputs..."
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json

# Extract the Lex bot ID and version
$lexBotId = $outputs.lex_bot_id.value

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version
    Write-Host "AWS CLI is installed: $awsVersion"
}
catch {
    Write-Host "AWS CLI is not installed or not in PATH. Please install AWS CLI and configure it."
    exit 1
}

# Check if the user is logged in to AWS
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "Authenticated as: $($identity.Arn)"
}
catch {
    Write-Host "Not authenticated with AWS. Please run 'aws configure' to set up your credentials."
    exit 1
}

# Get the latest bot version
Write-Host "Getting the latest bot version..."
$botVersions = aws lexv2-models list-bot-versions --bot-id $lexBotId | ConvertFrom-Json
if (-not $botVersions.botVersionSummaries) {
    Write-Host "No bot versions found for bot ID: $lexBotId"
    exit 1
}

# Sort versions and get the latest one (excluding DRAFT)
$latestVersion = $botVersions.botVersionSummaries | 
    Where-Object { $_.botVersion -ne "DRAFT" } | 
    Sort-Object -Property { [int]$_.botVersion } -Descending | 
    Select-Object -First 1 -ExpandProperty botVersion

if (-not $latestVersion) {
    Write-Host "No numeric bot versions found. Using the DRAFT version."
    $latestVersion = "DRAFT"
}

Write-Host "Latest bot version: $latestVersion"

# Create the bot alias
$aliasName = "prod"
Write-Host "Creating bot alias '$aliasName' for bot ID: $lexBotId with version: $latestVersion"

try {
    # Check if the alias already exists
    $existingAliases = aws lexv2-models list-bot-aliases --bot-id $lexBotId | ConvertFrom-Json
    $existingAlias = $existingAliases.botAliasSummaries | Where-Object { $_.botAliasName -eq $aliasName }
    
    if ($existingAlias) {
        Write-Host "Bot alias '$aliasName' already exists with ID: $($existingAlias.botAliasId)"
        Write-Host "Updating the alias to use version: $latestVersion"
        
        # Update the existing alias
        $updateResult = aws lexv2-models update-bot-alias `
            --bot-alias-id $existingAlias.botAliasId `
            --bot-id $lexBotId `
            --bot-version $latestVersion | ConvertFrom-Json
            
        $botAliasId = $updateResult.botAliasId
        Write-Host "Bot alias updated successfully with ID: $botAliasId"
    }
    else {
        # Create a new alias
        Write-Host "Creating new bot alias with command:"
        Write-Host "aws lexv2-models create-bot-alias --bot-id $lexBotId --bot-alias-name $aliasName --bot-version $latestVersion"
        
        # Create sentiment analysis settings JSON file
        $sentimentSettingsJson = @{
            detectSentiment = $false
        } | ConvertTo-Json -Compress
        
        # Save to temporary file
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $sentimentSettingsJson
        
        Write-Host "Using sentiment settings from file: $tempFile"
        
        # Create the alias using the file for sentiment settings
        $createResult = aws lexv2-models create-bot-alias `
            --bot-id $lexBotId `
            --bot-alias-name $aliasName `
            --bot-version $latestVersion `
            --sentiment-analysis-settings "file://$tempFile" | ConvertFrom-Json
            
        # Clean up temp file
        Remove-Item -Path $tempFile
        
        $botAliasId = $createResult.botAliasId
        Write-Host "Bot alias created successfully with ID: $botAliasId"
    }
    
    # Verify the alias was created or updated
    Write-Host "Verifying bot alias creation..."
    $verifyAliases = aws lexv2-models list-bot-aliases --bot-id $lexBotId | ConvertFrom-Json
    $verifyAlias = $verifyAliases.botAliasSummaries | Where-Object { $_.botAliasName -eq $aliasName }
    
    if ($verifyAlias) {
        $botAliasId = $verifyAlias.botAliasId
        Write-Host "Verified: Bot alias '$aliasName' exists with ID: $botAliasId"
        
        # Update the variables.tf file with the bot alias ID
        Write-Host "Updating IaC/variables.tf with the bot alias ID..."
        $variablesContent = Get-Content -Path IaC/variables.tf -Raw
        $variablesContent = $variablesContent -replace 'default\s+=\s+"XXXXXXXXXX"\s+# Replace with your actual Bot Alias ID', "default     = `"$botAliasId`" # Actual Bot Alias ID"
        Set-Content -Path IaC/variables.tf -Value $variablesContent
        
        # Run the update-config script to update all configuration files
        Write-Host "Running update-config.ps1 to update all configuration files..."
        & ./update-config.ps1 -botAliasId $botAliasId
        
        Write-Host "Bot alias creation and configuration update completed successfully!"
    } else {
        Write-Host "ERROR: Bot alias '$aliasName' was not found after creation attempt!"
        Write-Host "Available aliases:"
        $verifyAliases.botAliasSummaries | ForEach-Object {
            Write-Host "  - $($_.botAliasName) (ID: $($_.botAliasId))"
        }
        
        Write-Host "Failed to create or verify bot alias. Exiting."
        exit 1
    }
}
catch {
    Write-Host "Error creating or updating bot alias: $_"
    exit 1
}