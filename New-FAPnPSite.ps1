<#
.Synopsis
Adds new-pnp site (No provisioning necessary)
.Description
PnP Sites are created via user input for Title, Alias, and Type. PnP creation also creates an
associated unified group and provides a SharePoint URL, which does not require provisioning. 
.Example

#>

function New-FAPnPSite {
    [CmdletBinding()]

    $Name = Read-Host "Please enter a name for the site" 
    $Type = Read-Host "Please specify the site type - Team/Communication"


    if ((get-unifiedgroup).alias -contains $Name) {
        Write-Host "Group $Name already exists, please amend and try again." -ForegroundColor Yellow
    }

    elseif ($Type -ieq 'Team') {
        New-PnPSite -Title $Name -Alias $Name -Type $Type

        Write-Host "$Type Site $Name has now been created" -ForegroundColor Green
    }
    elseif ($Type -ieq 'Communication') {
        New-PnPSite -Type $Type -Title $Name -Url https://fletchersonline.sharepoint.com/Sites/$Name 
        # ^^^ Bug with this wherein sometimes the script will fail to create a communication site.
        #This appears to be resolved by copying and re-pasting the URL in the URL parameter, then re-running the script???

        Write-Host "$Type Site $Name has now been created" -ForegroundColor Green
    } 
}
New-FAPnPSite


#New-PnPSite has now have been created.