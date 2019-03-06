<#
.Synopsis
Removes user(s) from unified groups.
.Description
This cmdlet will remove a user or users from specific or all unified groups.
.Example
Remove-UnifiedGRoupLinks -Identity Azure -LinkType Members -Links Test.User

Adds new User to Microsoft Azure Active Directory
#>

$user = read-host "Please specify user to be removed from group"
Write-Host
$groups = get-unifiedgroup

foreach ($group in $groups) {

    Write-Output "Removing from $($group.Alias)" 

    Remove-UnifiedGroupLinks -Identity $group.Alias -Links $user -LinkType Members -Confirm:$false
}

Write-Host "$user has now been removed from groups" -ForegroundColor Green