<#
    .SYNOPSIS
    This script creates Azure Active Directory security groups.
    The name is constructed based on the input parameters.

    Make sure the AppID that is used to run this script has sufficient permissions, as follows: 
    - Group.ReadWrite.All

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
    Write-Verbose "|--------------------------------------------------|"
    Write-Verbose "| Authenticating to Microsoft Graph API..."
    Write-Verbose "|--------------------------------------------------|"

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

# region Groups
$InformationPreference = "Continue"
$securityGroupCntrName = "secgrp" + "-sub-cntr-" + $environment + "-" + $uniqueName
$securityGroupReadName = "secgrp" + "-sub-read-" + $environment + "-" + $uniqueName

# Check if Security Group already exists
$CntrGroupExisting = Get-MgGroup -Filter "DisplayName eq '$securityGroupCntrName'"
$ReadGroupExisting = Get-MgGroup -Filter "DisplayName eq '$securityGroupReadName'"

# Contributor Security Group
if($CntrGroupExisting){
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| No changes made, Azure Active Directory security group with name $($CntrGroupExisting.DisplayName) already exists."
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|`n"
}
else{
    # Create group
    $newGroupContr = New-MgGroup -DisplayName $securityGroupCntrName -MailEnabled:$false -SecurityEnabled -MailNickname "NotSet"
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| New Azure Active Directory security group created with name $($newGroupContr.DisplayName)."
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|`n"
}

# Reader Security Group
if($ReadGroupExisting){
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| No changes made, Azure Active Directory security group with name $($ReadGroupExisting.DisplayName) already exists."
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|`n"
}
else{
    # Create group
    $newGroupRead = New-MgGroup -DisplayName $securityGroupReadName -MailEnabled:$false -SecurityEnabled -MailNickname "NotSet"
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|"
    Write-Output "| New Azure Active Directory security group created with name $($newGroupRead.DisplayName)."
    Write-Output "|---------------------------------------------------------------------------------------------------------------------|`n"
}
# endregion Groups

# Disconnect
Disconnect-MgGraph