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
$repo = "private_app_on_azure"  # Replace with your GitHub repository name

# Create a folder under admin directory
cd C:/
mkdir actions-runner; cd actions-runner
# Download the latest runner package
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-win-x64-2.321.0.zip -OutFile actions-runner-win-x64-2.321.0.zip
# Extract the installer
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.321.0.zip", "$PWD")
# Make the API call to get the registration token
$response = Invoke-RestMethod -Uri "https://api.github.com/repos/$org/$repo/actions/runners/registration-token" `
    -Method Post `
    -Headers @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $token"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
# Extract the token from the response
$registrationToken = $response.token
# Create the runner and start running as a service
./config.cmd --runasservice --unattended --url https://github.com/$org/$repo/ --token $registrationToken --replace

# Install az cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi;
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet';
az --version
