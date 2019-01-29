<#
.Synopsis
Adds new-pnp site (No provisioning necessary)
.Description
PnP Sites are created via user input for Title, Alias, and Type. PnP creation also creates an
associated unified group and provides a SharePoint URL, which does not require provisioning. 
.Example

#>


$Name = Read-Host "Please enter a name for the site" 
$Type = Read-Host "Please specify the type of this site - Team/Communication"
$Url = https://sharepoint121.sharepoint.com/sites/$Name


if ((get-unifiedgroup).alias -contains $Name) {
    Write-Host "Group $Name already exists, please amend and try again." -ForegroundColor Yellow
}

elseif ($Type -ieq 'Team') {
    Write-Host "$Type Site '$Name' will be created" -ForegroundColor Green
    New-PnPSite -Title $Name -Alias $Name -Type $Type

    Write-Host "$Type Site $Name has now been created" -ForegroundColor Green
}
elseif ($Type -ieq 'Communication') {
    Write-Host "$Type Site '$Name' will be created" -ForegroundColor Green
    New-PnPSite -Type $Type -Title $Name -Url $Url

    Write-Host "$Type Site $Name has now been created" -ForegroundColor Green
} 




#New-PnPSite has now have been created.