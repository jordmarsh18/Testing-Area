<#
.Synopsis
Add singular users to every internal/client group and a specified security group, via user input values.
.Description
This cmdlet can add an Office 365 user to any groups associated with the tenant, as well as MFA security groups.
Following this, the user will receive an email informing them of their inclusion into the group.
.Example
Add-UnifiedGroupLinks -Identity TestGroup -LinkType Members -Links John.Smith@Contoso.com 

Adds the user John Smith to the Test Group specifically
#>

$groups = Get-UnifiedGroup
$user = Read-Host "Please specify user to be moved into groups" #E.g Jordan.Marsh, Ben.Golding, etc
Write-Host 


foreach ($group in $groups) {

    Write-Output "Adding $user to $($group.Alias)" 

    Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $user 
}

$msolproceed = Read-Host "Please specify an MFA security group for the $user to be added into - MDM/MDM (Soft)"
Write-Host
Write-Host "Adding $user to security group. To halt process, please select your ctrl + c keys." -ForegroundColor Yellow
Start-Sleep -Seconds 10


if ($msolproceed -ieq "MDM") {
    $msolGroup = Get-MsolGroup -GroupType Security | Where-Object {$_.displayname -eq "MDM"}
    $msoluser = Get-MsolUser | Where-Object {$_.userprincipalname -eq $user + '@fletcher-associates.co.uk'}
    Add-MsolGroupMember -GroupObjectId $msolGroup.ObjectId -GroupMemberObjectId $msoluser.ObjectId -GroupMemberType "User" 
}
elseif ($msolproceed -ieq "MDM (Soft)") {
    $msolGroup = Get-MsolGroup -GroupType Security | Where-Object {$_.displayname -eq "MDM (Soft)"}
    $msoluser = Get-MsolUser | Where-Object {$_.userprincipalname -eq $user + '@fletcher-associates.co.uk'}
    Add-MsolGroupMember -GroupObjectId $msolGroup.ObjectId -GroupMemberObjectId $msoluser.ObjectId -GroupMemberType "User" 
}

Write-Host "$user has now been added to interal, client, and security groups." -ForegroundColor Cyan




####Add all users in Fletcher Associates group to every internal/client group - I.E when a new Client is created####

<#
$groups = Get-UnifiedGroup
$members = (Get-UnifiedGroupLinks -LinkType Members -Identity FletcherAssociates | 
    Where-Object -Property 'Name' -NE 'Jordan.Marsh').PrimarySmtpAddress 

    foreach ($group in $groups) {

        Write-Output "Adding members to $($group.Alias)" 
    
        Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $members 
    }

    Write-Host "Fletcher Associates Members have now been added to internal/client groups." -Foregroundcolor Green
    #>
