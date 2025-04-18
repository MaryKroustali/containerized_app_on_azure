# Edit below commands based on guidelines in 
# Github Repository Settings > Actions > Runners > New self-hosted runner (Windows)
# Additionally to run as a service follow instructions on
# https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service


# Define your variables
param(
    [Parameter(Mandatory=$true)]
    [string]$token    # GitHub API token passed as a script parameter from Bicep
)

$org = "MaryKroustali"  # Replace with your GitHub organization name
$repo = "containerized_app_on_azure"  # Replace with your GitHub repository name
$dockerVersion = "25.0.3"  # Change this to latest version if needed
$downloadUrl = "https://download.docker.com/win/static/stable/x86_64/docker-$dockerVersion.zip"
$installPath = "$env:ProgramFiles\Docker\CLI"

# Set Github Runner
cd C:/ # Create a folder under admin directory
mkdir actions-runner; cd actions-runner # Download the latest runner package
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-win-x64-2.323.0.zip -OutFile actions-runner-win-x64-2.323.0.zip # Extract the installer
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.323.0.zip", "$PWD")
$response = Invoke-RestMethod -Uri "https://api.github.com/repos/$org/$repo/actions/runners/registration-token" `
    -Method Post `
    -Headers @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $token"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
$registrationToken = $response.token # Extract the token from the response
./config.cmd --runasservice --unattended --url https://github.com/$org/$repo/ --token $registrationToken --replace # Create the runner and start running as a service

# Install az cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi;
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet';
az --version

# Install Docker
New-Item -ItemType Directory -Force -Path $installPath # Create install directory
$tempZip = "$env:TEMP\docker.zip" # Download Docker CLI zip
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip
Expand-Archive -Path $tempZip -DestinationPath $installPath -Force # Extract the zip
$envPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) # Add to PATH (if not already)
if (-not $envPath.Contains($installPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$installPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Docker CLI path added to system PATH. You may need to restart your terminal."
}
Move-Item "C:\Program Files\Docker\CLI\docker\*" "C:\Program Files\Docker\CLI"
Remove-Item "C:\Program Files\Docker\CLI\docker" -Recurse
docker --version
