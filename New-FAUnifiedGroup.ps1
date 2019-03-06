<#
.Synopsis
Adds Unified Group to Tenant using Script User input.
.Description
Groups are created using values from the client list for alias, display name, etc.
.Example

#>
function New-FAUnifiedGroup {
    [CmdletBinding()]

    $Name = Read-Host "Please enter a name for the group" 
    $parameters = @{

        'AutoSubscribeNewMembers' = $true ;

        'AccessType'              = 'Private' ;

        'Language'                = (Get-Culture) ;

        'Owner'                   = 'sysadmin@fletcher-dev.co.uk' ;

    }
    if ((get-unifiedgroup).alias -contains $Name) {
        Write-Host "Group $Name already exists, please amend and try again." -ForegroundColor Yellow
    }

    else {
        Write-Host "Group '$Name' will be created" -ForegroundColor Green
        New-UnifiedGroup $parameters -alias $Name -DisplayName $Name
    }
}
New-FAUnifiedGroup

#New-Unified Group has now have been created.