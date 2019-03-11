#A collection of Powershell cmdlets, functions, and scripts, unified into a singe module.
#Adds new User to Fletcher Associates Azure Active Directory

Function New-FAUser {
    [CmdletBinding()]

    $Credential = Get-Credential
    Connect-MsolService -Credential $Credential

    $Firstname = Read-Host "Enter the First Name"
    Write-Host
    $LastName = Read-Host "Enter the Last Name"
    Write-Host
    $Displayname = $Firstname + " " + $LastName
    $UserType = Read-Host "Enter the User Type - Member/Guest"
    $UseageLocation = Read-Host "Please enter in the two letter country code for this license"
    #$link = $Firstname + ".$LastName"

    #Acquire domain from Get-MSolDomain command and filter out onmicrosoft.com
    #If a domain is not found, it will revert to the onmicrosoft.com domain

    $Domain = Get-MsolDomain | Where-Object {($_.Name -notmatch ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name
    if (-not $Domain) {$Domain = Get-MsolDomain | Where-Object {($_.Name -match ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name}
 
    $UserPrincipalName = $FirstName + ".$LastName" + "@$Domain"

    Write-Host "First Name: $Firstname"
    Write-Host "Last Name: $LastName"
    Write-Host "DisplayName: $Displayname"
    Write-Host "UserName: $UserPrincipalName"
    Write-Host "UserType: $UserType"
    Write-Host "Domain: $Domain"
    Write-Host "Location: $UseageLocation"

    #Check if an O365 account already exists
    Do {
        if ([bool] (Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction SilentlyContinue)) {
            Write-Host "Login name" $UserPrincipalName.ToUpper() "already exists - please review!" -ForegroundColor Yellow
            $UserPrincipalName = $FirstName + $LastName + "@$Domain"
            Write-Host
            Write-Host "Changing Login name to" $UserPrincipalName.toUpper() -ForegroundColor Yellow
            Write-Host
            $Taken = $true
    
        }
        else {
            $taken = $false
        }
    } Until ($taken -eq $false)
    $UserPrincipalName = $UserPrincipalName.ToLower()

    $Proceed = Read-Host "Proceed with user creation - Y/N?"

    if ($Proceed -ieq 'Y') {
        New-MsolUser -DisplayName $DisplayName -FirstName $FirstName -LastName $LastName -UserPrincipalName $UserPrincipalName -UserType $UserType -UsageLocation $UseageLocation

        Get-MsolUser -UserPrincipalName $UserPrincipalName

        Write-Host "User '$Displayname' will now be created" -ForegroundColor Green

        #May take out later - test first
        #Add-UnifiedGroupLinks -identity FletcherAssociates -Linktype Members -Links $link 

        <#Upon completion, the account should now be appearing under Active Users in the O365 Admin Centre, awaiting 
    license assignment and password input#>

    }
    else {
        Write-Host "User Creation process cancelled" -ForegroundColor Yellow
    }
}


#New Unified Group on Fletcher Associates tenant
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

#Creates new PnP site on Fletcher Associates tenant
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

#Adds Fletcher Associates tenant user to groups
function Add-FAUsertoGroup {
    [CmdletBinding()]

    $groups = Get-UnifiedGroup
    $user = Read-Host "Please specify user to be moved into groups" #Insert User I.E Ben.Golding, Jordan.Marsh, etc
    Write-Host 


    foreach ($group in $groups) {

        Write-Output "Adding members to $($group.Alias)" 

        Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $user
    }
    Write-Host "$user has now been added to groups" -ForegroundColor Cyan
}

function Add-FAUsertoIntCliSecGroup {
    [CmdletBinding()]
    $groups = Get-UnifiedGroup
$user = Read-Host "Please specify user to be moved into groups" #E.g Jordan.Marsh, Ben.Golding, etc
Write-Host 

#Adds to Unified Groups

foreach ($group in $groups) {

    Write-Output "Adding $user to $($group.Alias)" 

    Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $user 
}

#Adds to Security Groups

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

#Output

Write-Host "$user has now been added to internal, client, and security groups." -ForegroundColor Cyan

}

#Add all users in the Fletcher Associates group to all other unified groups

function Add-allFAMemberstoGroup {
    [CmdletBinding()]
    $groups = Get-UnifiedGroup
    $members = (Get-UnifiedGroupLinks -LinkType Members -Identity FletcherAssociates | 
        Where-Object -Property 'Name' -NE 'Jordan.Marsh').PrimarySmtpAddress 
    
        foreach ($group in $groups) {
    
            Write-Output "Adding members to $($group.Alias)" 
        
            Add-UnifiedGroupLinks -Identity $group.Alias -LinkType Members -Links $members 
        }
    
        Write-Host "Fletcher Associates Members have now been added to internal/client groups." -Foregroundcolor Green

}