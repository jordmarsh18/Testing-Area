function Add-FAUsertoGroup {
    [CmdletBinding()]

    $groups = Get-UnifiedGroup

    $members = (Get-UnifiedGroupLinks -LinkType Members -Identity FletcherAssociates | 

        Where-Object -Property 'Name' -NE 'Jordan.Marsh').PrimarySmtpAddress 
    $user = Read-Host "Please specify user to be moved into groups:"
    Write-Host 


    foreach ($group in $groups) {

        Write-Output "Adding members to $($group.Alias)" 

        Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $user #Insert User I.E Ben.Golding, Jordan.Marsh, etc
    }
    Write-Host "$user has now been added to groups" -ForegroundColor Cyan
}

Add-FAUsertoGroup
