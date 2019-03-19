#Complete - works


#External User/Group Permissions Test 3.0

#This command set adds PnP role definitions and groups

$group = get-unifiedgroup -filter {alias -like "TeamSiteTest"}
Connect-PnPOnline -Url $group.SharepointSiteUrl
Add-PnPRoleDefinition -RoleName "Custom" -Description "For External Users: Read Permissions, excluding Versioning" -Clone "Read" -Exclude ViewVersions
New-PnPGroup -Title ($group.DisplayName + " External Users")
Set-PnPGroupPermissions -Identity ($group.DisplayName + " External Users") -AddRole "Custom"

Write-Host "Role definitions and permission for group $group have now been amended." -ForegroundColor Green

#This creates the guest user using AzureAD

Connect-AzureAD
$firstName = Read-host "Please enter in the first name"
$lastName = Read-Host "Please enter in the last name"
$postion = Read-Host "Please enter in the position of the user"
$company = Read-Host "Please enter in the company"
$number = Read-Host "Please enter in the contact number of the user"
$email = Read-Host "Please enter in the email address of the guest user"

New-AzureADMSInvitation  -InvitedUserDisplayName "$firstName $lastName" -InvitedUserEmailAddress $email -InviteRedirectUrl https://www.office.com/?auth=2 -SendInvitationMessage $true

Start-Sleep -Seconds 5

#This adds the above user details to the access list in SharePoint

$Add = Add-PnPListItem -List "Access List" -Values @{
    "v7o5" = $firstName; 
    "a4s2" = $lastName;
    "czsy" = $postion;
    "bioz" = $company;
    "_x0073_v37" = $number;
    "bpan" = $email;
}

#This adds the user to the newly created custom access group

$users = Get-PnPListItem -List "Access List" #List name goes here
foreach ($user in $users) {
    $Adduser = Add-PnPUserToGroup -EmailAddress $user['bpan'] -Identity ($group.DisplayName + " External Users") #-SendEmail -EmailBody "This is an invitation email" -Verbose
} #end foreach

#output message
Write-Host "The guest user has now been created, with groups/permissions assigned, and invitation sent." -ForegroundColor Green