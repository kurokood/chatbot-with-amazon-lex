# PowerShell script to configure Lex intents, slots, and responses
# This script automates the manual configuration of Lex intents

# Get the Terraform outputs
Write-Host "Getting Terraform outputs..."
$outputs = terraform -chdir=IaC output -json | ConvertFrom-Json

# Extract the Lex bot ID
$lexBotId = $outputs.lex_bot_id.value
Write-Host "Using Lex Bot ID: $lexBotId"

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

# Get all intents
Write-Host "Getting existing intents..."
$intents = aws --no-cli-pager lexv2-models list-intents --bot-id $lexBotId --locale-id "en_US" --bot-version "DRAFT" | ConvertFrom-Json

# Configure StartMeety Intent
Write-Host "Configuring StartMeety intent..."
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

$closingSettingJson = @{
    active = $true
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
    nextStep = @{
        dialogAction = @{
            type = "EndConversation"
        }
    }
} | ConvertTo-Json -Depth 10 -Compress

$closingResponseFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $closingResponseFile -Value $closingSettingJson

try {
    aws --no-cli-pager lexv2-models update-intent `
        --bot-id $lexBotId `
        --bot-version "DRAFT" `
        --locale-id "en_US" `
        --intent-id $startMeetyIntentId `
        --intent-name "StartMeety" `
        --description "Intent for greeting and starting conversations" `
        --sample-utterances "utterance=Hello" "utterance=Hi" "utterance=Hey Meety" "utterance=help" `
        --intent-closing-setting "file://$closingResponseFile"
    
    Write-Host "Successfully updated StartMeety intent"
}
catch {
    Write-Host "Error updating StartMeety intent: $($_.Exception.Message)"
}
finally {
    Remove-Item -Path $closingResponseFile -ErrorAction SilentlyContinue
}

# Configure MeetingAssistant Intent
Write-Host "Configuring MeetingAssistant intent..."
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

# First, get existing slots and delete them
Write-Host "Getting existing slots..."
try {
    $existingSlots = aws --no-cli-pager lexv2-models list-slots `
        --bot-id $lexBotId `
        --locale-id "en_US" `
        --intent-id $meetingAssistantIntentId `
        --bot-version "DRAFT" | ConvertFrom-Json
    
    if ($existingSlots.slotSummaries -and $existingSlots.slotSummaries.Count -gt 0) {
        Write-Host "Deleting $($existingSlots.slotSummaries.Count) existing slots..."
        foreach ($existingSlot in $existingSlots.slotSummaries) {
            Write-Host "Deleting slot: $($existingSlot.slotName)"
            try {
                aws --no-cli-pager lexv2-models delete-slot `
                    --bot-id $lexBotId `
                    --bot-version "DRAFT" `
                    --locale-id "en_US" `
                    --intent-id $meetingAssistantIntentId `
                    --slot-id $existingSlot.slotId
            }
            catch {
                Write-Host "Warning: Could not delete slot $($existingSlot.slotName): $($_.Exception.Message)"
            }
        }
        
        Write-Host "Waiting for slot deletion to complete..."
        Start-Sleep -Seconds 5
    }
}
catch {
    Write-Host "Warning: Could not list existing slots: $($_.Exception.Message)"
}

# Update MeetingAssistant intent with initial response and fulfillment
Write-Host "Updating MeetingAssistant intent with initial response and fulfillment..."

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
    nextStep = @{
        dialogAction = @{
            type = "InvokeDialogCodeHook"
        }
    }
} | ConvertTo-Json -Depth 10 -Compress

$fulfillmentCodeHookJson = @{
    enabled = $true
} | ConvertTo-Json -Compress

$dialogCodeHookJson = @{
    enabled = $false
} | ConvertTo-Json -Compress

$initialResponseFile = [System.IO.Path]::GetTempFileName()
$fulfillmentCodeHookFile = [System.IO.Path]::GetTempFileName()
$dialogCodeHookFile = [System.IO.Path]::GetTempFileName()

Set-Content -Path $initialResponseFile -Value $initialResponseJson
Set-Content -Path $fulfillmentCodeHookFile -Value $fulfillmentCodeHookJson
Set-Content -Path $dialogCodeHookFile -Value $dialogCodeHookJson

try {
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
    
    Write-Host "Successfully updated MeetingAssistant intent"
}
catch {
    Write-Host "Error updating MeetingAssistant intent: $($_.Exception.Message)"
}
finally {
    Remove-Item -Path $initialResponseFile -ErrorAction SilentlyContinue
    Remove-Item -Path $fulfillmentCodeHookFile -ErrorAction SilentlyContinue
    Remove-Item -Path $dialogCodeHookFile -ErrorAction SilentlyContinue
}

# Create slots for MeetingAssistant intent
Write-Host "Creating slots for MeetingAssistant intent..."

# Function to create a slot
function Create-Slot {
    param (
        [string]$name,
        [string]$slotTypeId,
        [string]$prompt,
        [bool]$required,
        [int]$priority
    )
    
    Write-Host "Creating slot ${priority}: ${name} with type ID: $slotTypeId"
    
    $slotConstraint = if ($required) { "Required" } else { "Optional" }
    
    $valueElicitationJson = @{
        slotConstraint = $slotConstraint
        promptSpecification = @{
            messageGroups = @(
                @{
                    message = @{
                        plainTextMessage = @{
                            value = $prompt
                        }
                    }
                }
            )
            maxRetries = 3
            allowInterrupt = $true
        }
    } | ConvertTo-Json -Depth 10 -Compress
    
    $valueElicitationFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $valueElicitationFile -Value $valueElicitationJson
    
    try {
        $createSlotResult = aws --no-cli-pager lexv2-models create-slot `
            --bot-id $lexBotId `
            --bot-version "DRAFT" `
            --locale-id "en_US" `
            --intent-id $meetingAssistantIntentId `
            --slot-name $name `
            --slot-type-id $slotTypeId `
            --value-elicitation-setting "file://$valueElicitationFile" | ConvertFrom-Json
        
        Write-Host "Successfully created slot $name with ID: $($createSlotResult.slotId)"
        Start-Sleep -Seconds 3
        return $createSlotResult.slotId
    }
    catch {
        Write-Host "Error creating slot $name : $($_.Exception.Message)"
        return $null
    }
    finally {
        Remove-Item -Path $valueElicitationFile -ErrorAction SilentlyContinue
    }
}

Write-Host "Creating slots with alphabetical prefixes to force correct order:"
Write-Host "1.a_FullName 2.b_MeetingDate 3.c_MeetingTime 4.d_MeetingDuration 5.e_AttendeeEmail 6.f_Confirm"

# Create slots with alphabetical prefixes to force correct ordering
Write-Host "Creating slots with alphabetical prefixes to ensure correct order..."
$createdSlots = @()
$createdSlots += Create-Slot -name "a_FullName" -slotTypeId "AMAZON.FirstName" -prompt "Sure! What is your name?" -required $true -priority 1
$createdSlots += Create-Slot -name "b_MeetingDate" -slotTypeId "AMAZON.Date" -prompt "What date would you like to schedule the meeting for?" -required $true -priority 2
$createdSlots += Create-Slot -name "c_MeetingTime" -slotTypeId "AMAZON.Time" -prompt "What time would you prefer for the meeting?" -required $true -priority 3
$createdSlots += Create-Slot -name "d_MeetingDuration" -slotTypeId "AMAZON.Duration" -prompt "How long do you want to meet in minutes? (30 or 60)" -required $true -priority 4
$createdSlots += Create-Slot -name "e_AttendeeEmail" -slotTypeId "AMAZON.EmailAddress" -prompt "Please provide me your email address." -required $true -priority 5
$createdSlots += Create-Slot -name "f_Confirm" -slotTypeId "AMAZON.Confirmation" -prompt "Do you want to proceed with the meeting?" -required $true -priority 6

Write-Host "Created $($createdSlots.Count) slots successfully"

# Verify final slot configuration
Write-Host "Verifying final slot configuration..."
try {
    $finalSlots = aws --no-cli-pager lexv2-models list-slots `
        --bot-id $lexBotId `
        --locale-id "en_US" `
        --intent-id $meetingAssistantIntentId `
        --bot-version "DRAFT" | ConvertFrom-Json
    
    Write-Host "Final slots in MeetingAssistant intent:"
    if ($finalSlots.slotSummaries) {
        $finalSlots.slotSummaries | ForEach-Object { 
            Write-Host "- $($_.slotName) (ID: $($_.slotId))" 
        }
    } else {
        Write-Host "No slots found in the intent"
    }
}
catch {
    Write-Host "Could not verify slots: $($_.Exception.Message)"
}

# Build the bot
Write-Host "Building the bot..."
try {
    $buildResult = aws --no-cli-pager lexv2-models build-bot-locale `
        --bot-id $lexBotId `
        --locale-id "en_US" `
        --bot-version "DRAFT" | ConvertFrom-Json
    
    Write-Host "Bot build initiated. Build ID: $($buildResult.buildId)"
    Write-Host "Bot build status: $($buildResult.botLocaleStatus)"
}
catch {
    Write-Host "Error building bot: $($_.Exception.Message)"
}

Write-Host "Lex intent configuration script completed!"
Write-Host "Note: The bot build process may take a few minutes to complete."
Write-Host "You can check the build status in the AWS Console under Amazon Lex > Bots > MeetyGenerativeBot"