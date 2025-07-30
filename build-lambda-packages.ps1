# PowerShell script to build Lambda deployment packages

Write-Host "Building Lambda deployment packages..."

# Function to create a Lambda package
function Build-LambdaPackage {
    param(
        [string]$SourceFile,
        [string]$OutputFile
    )
    
    Write-Host "Building $OutputFile from $SourceFile..."
    
    # Remove existing zip file if it exists
    if (Test-Path $OutputFile) {
        Remove-Item $OutputFile -Force
        Write-Host "Removed existing $OutputFile"
    }
    
    # Create zip file with the Python file
    Compress-Archive -Path $SourceFile -DestinationPath $OutputFile -Force
    
    Write-Host "Created $OutputFile successfully"
}

# Build all Lambda packages
try {
    # Change to the IaC/lambda directory
    Push-Location -Path "IaC/lambda"
    
    # Build each Lambda package
    Build-LambdaPackage -SourceFile "get_meetings.py" -OutputFile "get_meetings.zip"
    Build-LambdaPackage -SourceFile "get_pending_meetings.py" -OutputFile "get_pending_meetings.zip"
    Build-LambdaPackage -SourceFile "change_meeting_status.py" -OutputFile "change_meeting_status.zip"
    Build-LambdaPackage -SourceFile "meety_lex.py" -OutputFile "meety_lex.zip"
    
    Write-Host "All Lambda packages built successfully!"
}
catch {
    Write-Host "Error building Lambda packages: $_"
    exit 1
}
finally {
    Pop-Location
} 