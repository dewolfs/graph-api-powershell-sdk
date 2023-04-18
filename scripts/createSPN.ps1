<#
    .SYNOPSIS
    This script creates an Azure Application registration and an Enterprise Application.
    The name is constructed based on the input parameters.

    Make sure the AppID that is used to run this script has sufficient permissions, as follows: 
    - Application.ReadWrite.All

    .NOTES
    VERSION: 1.0

    .DATE
    18/04/2023
    
    .LICENSE
    Licensed under the MIT license.
#>

param(
    [string][parameter(Mandatory = $true)] $environment,
    [string][parameter(Mandatory = $true)] $uniqueName
)

# region Authentication
try {
    Write-Output "|--------------------------------------------------|"
    Write-Output "| Authenticating to Microsoft Graph API..."
    Write-Output "|--------------------------------------------------|`n"

    $body =  @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $env:clientId
        Client_Secret = $env:clientSecret
        }
        
    $connection = Invoke-RestMethod -Uri https://login.microsoftonline.com/$env:tenantId/oauth2/v2.0/token -Method POST -Body $body
    $token = $connection.access_token
    Connect-MgGraph -AccessToken $token

    $context = Get-MgContext | select -ExpandProperty Scopes

    Write-Output "|--------------------------------------------------|"
    Write-Output "| The available graph API scopes are: $($context)."
    Write-Output "|--------------------------------------------------|`n"
    }
catch {
    Write-Output "Unable to authenticate, exit..."
    Write-Output $_
    }
# endregion Authentication

 # region Azure AD Application registration
$InformationPreference = "Continue"
$SpnName = "spn" + "-sub-cntr-" + $environment + "-" + $uniqueName

# Check if SPN already exists
$SpnExisting = Get-MgApplication -Filter "DisplayName eq '$SpnName'"

if($SpnExisting){
    Write-Output "|--------------------------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| No changes made, Azure Active Directory Application registration with name $($SpnExisting.DisplayName) already exists."
    Write-Output "|--------------------------------------------------------------------------------------------------------------------------------------|`n"
    }
else{
    # Create App registration
    $app = New-MgApplication -DisplayName $SpnName
    # Create corresponding service principal.
    $output = New-MgServicePrincipal -AppId $app.AppId
    Write-Output "|--------------------------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| New Azure Active Directory Application registration and Enterprise Application created with name $($app.DisplayName)."
    Write-Output "|--------------------------------------------------------------------------------------------------------------------------------------|`n"
    }
# endregion Azure AD Application registration

# Disconnect
Disconnect-MgGraph