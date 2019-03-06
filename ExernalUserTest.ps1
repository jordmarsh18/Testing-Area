#Exernal Users/Group & Permissions

#Adds new PNP Roles & Groups
$group = Get-UnifiedGroup -filter {alias -like "TeamSiteTest"}

    Connect-PnPOnline -url $group.SharepointSiteURL 
    Add-PnPRoleDefinition -RoleName "Custom Read" -Description "Read Permissions excluding Versioning" -Clone "Read" -Exclude ViewVersions

    New-PnPGroup -Title ($group.DisplayName + " External Users")
    Set-PnPGroupPermissions -Identity ($group.DisplayName + " External Users") -AddRole "Custom Read"

    Write-Host "Role definition and permissions for $group have now been amended" -ForegroundColor Green



    #The below should pull the users from the 'Access' list
    <#NOTE - EXTERNAL USERS SHOULD BE CREATED THROUGH AZURE AD (NEW-AZUREADUSER) OR MSOL (NEW-MSOLUSER) CMDLETS BEFOREHAND (AS MEMBERS OR GUESTS) AND BE INCLUDED IN THE "ACCESS" LIST
IN ORDER FOR THEM TO BE ADDED TO THE GROUP#>

    $users = Get-PnPListItem -List 'Access'

    #This should add the users from the 'Access' list to the group created above
    foreach ($user in $users) {
        Add-PnPUserToGroup -EmailAddress $user['i4wy'] -Identity ($group.DisplayName + " External Users") -SendEmail -EmailBody 'This is a test invite email' -Verbose

    } #end foreach
    Write-host "The selected users have now been added, and emails sent" -ForegroundColor Green
