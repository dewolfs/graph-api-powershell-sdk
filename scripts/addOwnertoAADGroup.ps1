<#
    .SYNOPSIS
    This script creates set Owners to Azure AD security groups.

    Make sure the AppID that is used to run this script has sufficient permissions, as follows: 
    - Group.ReadWrite.All
    - Directory.ReadWrite.All

    .NOTES
    VERSION: 1.0

    .DATE
    18/04/2023
    
    .LICENSE
    Licensed under the MIT license.
#>

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

$json = Get-Content -Path "./input/azure-subs-01-groupOwners.json" | ConvertFrom-Json

# addOwner region
foreach ($item in $json.items) {
    
    Write-Output "|--------------------------------------------------|"
    Write-Output "| Input:"
    Write-Output "| - groupName: $($item.groupName)"
    Write-Output "| - groupOwner: $($item.groupOwner)"
    
    $groupId = (Get-MgGroup -Filter "DisplayName eq '$($item.groupName)'").id
    $userId = (Get-MgUser -Filter "userprincipalname eq '$($item.groupOwner)'").id

    Write-Output "| Retrieving details:"
    Write-Output "| - groupId: $groupId"
    Write-Output "| - userId: $userId"
    
    $params = @{
	    "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userid"
    }

    $newOwner = $userid
    $existingOwners = (Get-MgGroupOwner -GroupId $groupId | ForEach-Object { @{ userId=$_.Id}} | Get-MgUser).id 

    if ($existingOwners -contains $newOwner) {
        Write-Output "| User $($item.groupOwner) is already set as Owner of the group $($item.groupName)"
        Write-Output "|--------------------------------------------------|`n"
        }
    else {

        New-MgGroupOwnerByRef -GroupId $groupId -BodyParameter $params
        $currentOwner = (Get-MgGroupOwner -GroupId $groupId | ForEach-Object { @{ userId=$_.Id}} | Get-MgUser).DisplayName

        Write-Output "| Modifications:"
        Write-Output "| Group $($item.groupName) has the following owner(s): $currentOwner"
        Write-Output "|--------------------------------------------------|`n"
    }
}
# endregion addOwner

# Disconnect
Disconnect-MgGraph