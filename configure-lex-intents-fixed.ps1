# PowerShell script to configure Lex intents, slots, and responses
# This script automates the manual configuration of Lex intents

# Get the Terraform outputs
Write-Host "Getting Terraform outputs..."
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json

# Extract the Lex bot ID
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
    $identity = aws --no-cli-pager sts get-caller-identity | ConvertFrom-Json
    Write-Host "Authenticated as: $($identity.Arn)"
}
catch {
    Write-Host "Not authenticated with AWS. Please run 'aws configure' to set up your credentials."
    exit 1
}

# Get the bot locale
Write-Host "Getting bot locale..."
$botLocales = aws --no-cli-pager lexv2-models list-bot-locales --bot-id $lexBotId --bot-version "DRAFT" | ConvertFrom-Json
$enUsLocale = $botLocales.botLocaleSummaries | Where-Object { $_.localeId -eq "en_US" }

if (-not $enUsLocale) {
    Write-Host "No en_US locale found for bot ID: $lexBotId"
    exit 1
}

Write-Host "Found en_US locale with ID: $($enUsLocale.localeId)"

# Configure StartMeety Intent
Write-Host "Configuring StartMeety intent..."

# Get the StartMeety intent
$intents = aws --no-cli-pager lexv2-models list-intents --bot-id $lexBotId --locale-id "en_US" --bot-version "DRAFT" | ConvertFrom-Json
$startMeetyIntent = $intents.intentSummaries | Where-Object { $_.intentName -eq "StartMeety" }

if (-not $startMeetyIntent) {
    Write-Host "StartMeety intent not found. Creating it..."
    
    # Create the StartMeety intent
    $createIntentResult = aws --no-cli-pager lexv2-models create-intent `
        --bot-id $lexBotId `
        --locale-id "en_US" `
        --intent-name "StartMeety" `
        --description "Intent for greeting and starting conversations" | ConvertFrom-Json
    
    $startMeetyIntentId = $createIntentResult.intentId
    Write-Host "Created StartMeety intent with ID: $startMeetyIntentId"
} else {
    $startMeetyIntentId = $startMeetyIntent.intentId
    Write-Host "Found StartMeety intent with ID: $startMeetyIntentId"
}

# Update StartMeety intent with closing responses
Write-Host "Updating StartMeety intent with closing responses..."

# Create a temporary JSON file for the closing response with multiple variations
$closingResponseJson = @{
    closingResponse = @{
        messageGroups = @(
            @{
                message = @{
                    plainTextMessage = @{
                        value = "Hi! I'm Meety, your meeting assistant. How can I help you schedule a meeting today?"
                    }
                }
                variations = @(
                    @{
                        plainTextMessage = @{
                            value = "Hello! how may i help you today?"
                        }
                    },
                    @{
                        plainTextMessage = @{
                            value = "Hi! how can i help you?"
                        }
                    }
                )
            }
        )
    }
} | ConvertTo-Json -Depth 10 -Compress

# Save to temporary file
$closingResponseFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $closingResponseFile -Value $closingResponseJson

# Update the intent using the file
aws --no-cli-pager lexv2-models update-intent `
    --bot-id $lexBotId `
    --bot-version "DRAFT" `
    --locale-id "en_US" `
    --intent-id $startMeetyIntentId `
    --intent-name "StartMeety" `
    --description "Intent for greeting and starting conversations" `
    --sample-utterances "utterance=Hello" "utterance=Hi" "utterance=Hey Meety" "utterance=help" `
    --intent-closing-setting "file://$closingResponseFile"

# Clean up temp file
Remove-Item -Path $closingResponseFile

# Configure MeetingAssistant Intent
Write-Host "Configuring MeetingAssistant intent..."

# Get the MeetingAssistant intent
$meetingAssistantIntent = $intents.intentSummaries | Where-Object { $_.intentName -eq "MeetingAssistant" }

if (-not $meetingAssistantIntent) {
    Write-Host "MeetingAssistant intent not found. Creating it..."
    
    # Create the MeetingAssistant intent
    $createIntentResult = aws --no-cli-pager lexv2-models create-intent `
        --bot-id $lexBotId `
        --locale-id "en_US" `
        --intent-name "MeetingAssistant" `
        --description "Intent for scheduling meetings" | ConvertFrom-Json
    
    $meetingAssistantIntentId = $createIntentResult.intentId
    Write-Host "Created MeetingAssistant intent with ID: $meetingAssistantIntentId"
} else {
    $meetingAssistantIntentId = $meetingAssistantIntent.intentId
    Write-Host "Found MeetingAssistant intent with ID: $meetingAssistantIntentId"
}

# Update MeetingAssistant intent with initial response
Write-Host "Updating MeetingAssistant intent with initial response..."

# Create temporary JSON files for the initial response and fulfillment code hook
$initialResponseJson = @{
    initialResponse = @{
        messageGroups = @(
            @{
                message = @{
                    plainTextMessage = @{
                        value = "Sure!"
                    }
                }
            }
        )
        allowInterrupt = $true
    }
} | ConvertTo-Json -Depth 10 -Compress

$fulfillmentCodeHookJson = @{
    enabled = $true
} | ConvertTo-Json -Compress

$dialogCodeHookJson = @{
    enabled = $false
} | ConvertTo-Json -Compress

# Save to temporary files
$initialResponseFile = [System.IO.Path]::GetTempFileName()
$fulfillmentCodeHookFile = [System.IO.Path]::GetTempFileName()
$dialogCodeHookFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $initialResponseFile -Value $initialResponseJson
Set-Content -Path $fulfillmentCodeHookFile -Value $fulfillmentCodeHookJson
Set-Content -Path $dialogCodeHookFile -Value $dialogCodeHookJson

# Update the intent using the files
aws --no-cli-pager lexv2-models update-intent `
    --bot-id $lexBotId `
    --bot-version "DRAFT" `
    --locale-id "en_US" `
    --intent-id $meetingAssistantIntentId `
    --intent-name "MeetingAssistant" `
    --description "Intent for scheduling meetings" `
    --sample-utterances "utterance=I want to schedule a meeting" "utterance=Book a meeting" "utterance=Schedule a meeting" "utterance=Set up a meeting" "utterance=Create a meeting" "utterance=I need to schedule a meeting" "utterance=Help me book a meeting" `
    --initial-response-setting "file://$initialResponseFile" `
    --dialog-code-hook "file://$dialogCodeHookFile" `
    --fulfillment-code-hook "file://$fulfillmentCodeHookFile"

# Clean up temp files
Remove-Item -Path $initialResponseFile
Remove-Item -Path $fulfillmentCodeHookFile
Remove-Item -Path $dialogCodeHookFile

# Create slots for MeetingAssistant intent
Write-Host "Creating slots for MeetingAssistant intent..."

# First, get all existing slots
Write-Host "Getting existing slots..."
$existingSlots = aws --no-cli-pager lexv2-models list-slots `
    --bot-id $lexBotId `
    --locale-id "en_US" `
    --intent-id $meetingAssistantIntentId `
    --bot-version "DRAFT" | ConvertFrom-Json

# Delete all existing slots to ensure clean slate
if ($existingSlots.slotSummaries -and $existingSlots.slotSummaries.Count -gt 0) {
    Write-Host "Deleting existing slots to ensure proper ordering..."
    foreach ($existingSlot in $existingSlots.slotSummaries) {
        Write-Host "Deleting slot: $($existingSlot.slotName) with ID: $($existingSlot.slotId)..."
        aws --no-cli-pager lexv2-models delete-slot `
            --bot-id $lexBotId `
            --bot-version "DRAFT" `
            --locale-id "en_US" `
            --intent-id $meetingAssistantIntentId `
            --slot-id $existingSlot.slotId
    }
    
    # Wait a moment to ensure all slots are deleted
    Write-Host "Waiting for slot deletion to complete..."
    Start-Sleep -Seconds 3
}

# Fetch built-in slot type IDs for en_US locale
$slotTypes = aws --no-cli-pager lexv2-models list-slot-types `
    --bot-id $lexBotId `
    --locale-id "en_US" `
    --bot-version "DRAFT" | ConvertFrom-Json

function Get-SlotTypeId($slotTypeName) {
    return ($slotTypes.slotTypeSummaries | Where-Object { $_.slotTypeName -eq $slotTypeName }).slotTypeId
}

Write-Host "Creating slots with alphabetical prefixes to force correct order:"
Write-Host "1.a_FullName 2.b_MeetingDate 3.c_MeetingTime 4.d_MeetingDuration 5.e_AttendeeEmail 6.f_Confirm"

# Function to create a slot with the given parameters and explicit priority
function Create-Slot {
    param (
        [string]$name,
        [string]$type,
        [string]$prompt,
        [bool]$required,
        [int]$priority
    )
    
    Write-Host "Creating slot ${priority}: ${name}..."
    
    # Determine slot constraint
    $slotConstraint = if ($required) { "Required" } else { "Optional" }
    
    # Create a temporary JSON file for the value elicitation setting with priority
    $valueElicitationSettingJson = @{
        promptSpecification = @{
            maxRetries = 3
            messageGroups = @(
                @{
                    message = @{
                        plainTextMessage = @{
                            value = $prompt
                        }
                    }
                }
            )
        }
        slotConstraint = $slotConstraint
    } | ConvertTo-Json -Depth 10 -Compress
    
    # Save to temporary file
    $valueElicitationSettingFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $valueElicitationSettingFile -Value $valueElicitationSettingJson
    
    # Create the slot using the file (AWS CLI doesn't support --priority parameter)
    $createSlotResult = aws --no-cli-pager lexv2-models create-slot `
        --bot-id $lexBotId `
        --bot-version "DRAFT" `
        --locale-id "en_US" `
        --intent-id $meetingAssistantIntentId `
        --slot-name $name `
        --slot-type-id $type `
        --value-elicitation-setting "file://$valueElicitationSettingFile" | ConvertFrom-Json
    
    # Clean up temp file
    Remove-Item -Path $valueElicitationSettingFile
    
    Write-Host "Created slot $name with ID: $($createSlotResult.slotId)"
    
    # Add a longer delay to ensure proper ordering
    Start-Sleep -Seconds 3
}

# Create slots with alphabetical prefixes to force correct ordering
Write-Host "Creating slots with alphabetical prefixes to ensure correct order..."
Create-Slot -name "a_FullName" -type "AMAZON.FirstName" -prompt "What is your name?" -required $true -priority 1
Create-Slot -name "b_MeetingDate" -type "AMAZON.Date" -prompt "What date would you like to schedule the meeting for?" -required $true -priority 2
Create-Slot -name "c_MeetingTime" -type "AMAZON.Time" -prompt "What time would you prefer for the meeting?" -required $true -priority 3
Create-Slot -name "d_MeetingDuration" -type "AMAZON.Duration" -prompt "How long do you want to meet in minutes? (30 or 60)" -required $true -priority 4
Create-Slot -name "e_AttendeeEmail" -type "AMAZON.EmailAddress" -prompt "Please provide me your email address." -required $true -priority 5
Create-Slot -name "f_Confirm" -type "AMAZON.Confirmation" -prompt "Do you want to proceed with the meeting?" -required $true -priority 6

# Verify slot order after creation
Write-Host "Verifying slot order..."
$finalSlots = aws --no-cli-pager lexv2-models list-slots `
    --bot-id $lexBotId `
    --locale-id "en_US" `
    --intent-id $meetingAssistantIntentId `
    --bot-version "DRAFT" | ConvertFrom-Json

Write-Host "Current slot order in Lex:"
$finalSlots.slotSummaries | ForEach-Object { Write-Host "- $($_.slotName)" }

# Note: FallbackIntent can be configured manually in AWS Console if needed

# Build the bot
Write-Host "Building the bot..."
aws --no-cli-pager lexv2-models build-bot-locale `
    --bot-id $lexBotId `
    --locale-id "en_US" `
    --bot-version "DRAFT"

Write-Host "Lex intent configuration completed successfully!"