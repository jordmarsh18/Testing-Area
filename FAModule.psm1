

<#This command creates a new Fletcher Associates user, which can be of the member or guest usertype. If it's the former, 
then onboarding can be completed by using the other follow up scripts/functions on this github account - e.g, Add-FAUsertoGroup, etc.
If it's the latter, then the command set also creates a PnP group and role definition aimed at external users, and adds
the guest user to a SharePoint list which details all external users currently with guest access.
#>
Function New-FAUser {
    [CmdletBinding()]
    $credential = Get-Credential
    Connect-MsolService -Credential $credential
    
    $usertype = Read-Host "Please specify type of user - Member/Guest?"
    ####MEMBER#### This creates the user as the Member type
    if ($usertype -ieq "Member") {
        $firstName = Read-Host "Please enter the first name"
        $lastName = Read-Host "Please enter the last name"
        $displayName = $firstName + " " + $lastName
        $usageLocation = "GB"
        
        #Acquire domain from Get-MSolDomain command and filter out onmicrosoft.com
        #If a domain is not found, it will revert to the onmicrosoft.com domain
        $domain = Get-MsolDomain | Where-Object {($_.Name -notmatch ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name
        if (-not $domain) {$domain = Get-MsolDomain | Where-Object {($_.Name -match ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name}
    
        $userPrincipalName = $FirstName + ".$LastName" + "@$Domain"
        
        Write-Host "First Name: $firstname"
        Write-Host "Last Name: $lastName"
        Write-Host "DisplayName: $displayname"
        Write-Host "UserName: $userPrincipalName"
        Write-Host "UserType: $userType"
        Write-Host "Domain: $domain"
        Write-Host "Location: $usageLocation"
    
        #Check if an O365 account already exists
        Do {
            if ([bool] (Get-MsolUser -UserPrincipalName $userPrincipalName -ErrorAction SilentlyContinue)) {
                Write-Host "Login name" $userPrincipalName.ToUpper() "already exists - please review!" -ForegroundColor Yellow
                $userPrincipalName = $firstName + $lastName + "@$domain"
                Write-Host
                Write-Host "Changing Login name to" $userPrincipalName.toUpper() -ForegroundColor Yellow
                Write-Host
                $Taken = $true
        
            }
            else {
                $taken = $false
            }
        } Until ($taken -eq $false)
        $userPrincipalName = $userPrincipalName.ToLower()
    
        $proceed = Read-Host "Proceed with user creation - Y/N?"
        if ($proceed -ieq "Y") {
            New-MsolUser -FirstName $firstName -LastName $lastName -DisplayName $displayName -UserPrincipalName $userPrincipalName -UserType $usertype -UsageLocation $usageLocation
            <#Set-MsolUserLicense - Possibly include license assignment at this point - need to test first. Unsure as to whether using this cmdlet when there's no
            licenses available would bring up an error message or whether it would infact just automatically purchase a new one, providing payment details were logged
            with the tenant. For the time being, continue with manual assignment through the O365 portal.
            #>
            Get-MsolUser -UserPrincipalName $userPrincipalName
            Write-Host "User '$displayName has now been created" -ForegroundColor Green
            
            #Upon completion, the user should be sat in the Office 365 user portal, awaiting license and password assignment.
        }
        else {
            Write-Host "User Creation process cancelled" -ForegroundColor Yellow
        }
    }
    ###Guest### This creates a user as the Guest type
    elseif ($usertype -ieq "Guest") {
        Connect-AzureAD
        $firstName = Read-host "Please enter in the first name"
        $lastName = Read-Host "Please enter in the last name"
        $postion = Read-Host "Please enter in the position of the user"
        $company = Read-Host "Please enter in the company"
        $number = Read-Host "Please enter in the contact number of the user"
        $email = Read-Host "Please enter in the email address of the guest user"
    
        New-AzureADMSInvitation  -InvitedUserDisplayName "$firstName $lastName" -InvitedUserEmailAddress $email -InviteRedirectUrl https://www.office.com/?auth=2 -SendInvitationMessage $true
    
        Start-Sleep -Seconds 5
    
        Write-Host "Guest user $firstName $lastName has now been created" -ForegroundColor Green
    
        $group = get-unifiedgroup -filter {alias -like "MemberGuestTestSite"}
        Connect-PnPOnline -Url $group.SharepointSiteUrl
        Add-PnPRoleDefinition -RoleName "Custom" -Description "For External Users: Read Permissions, excluding Versioning" -Clone "Read" -Exclude ViewVersions
        New-PnPGroup -Title ($group.DisplayName + " External Users")
        Set-PnPGroupPermissions -Identity ($group.DisplayName + " External Users") -AddRole "Custom"
    
        Write-Host "Role definitions and permission for group $group have now been amended/amended." -ForegroundColor Green
    
        $Add = Add-PnPListItem -List "External Access" -Values @{
            "First_x0020_Name"       = $firstName; 
            "Last_x0020_Name"       = $lastName;
            "Position"       = $postion;
            "Company"       = $company;
            "Contact_x0020_Number" = $number;
            "Email"       = $email;
        }
    
        #This adds the user to the newly created custom access group
    
        $users = Get-PnPListItem -List "External Access" #List name goes here
        foreach ($user in $users) {
            $Adduser = Add-PnPUserToGroup -EmailAddress $user['Email'] -Identity ($group.DisplayName + " External Users") #-SendEmail -EmailBody "This is an invitation email" -Verbose
        } #end foreach
    
        #output message
        Write-Host "The guest user $firstName $lastName has been created, with groups/permissions assigned, and site invitation sent." -ForegroundColor Green
    #>
    }
    
}

#This command creates a new Fletcher Associates Unified Group site

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

#This command creates a new Fletcher Associates PnP site

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

#This command adds a user to a the Fletcher Associates group:
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

#This command adds a user to the Fletcher Associates internal, client and security groups
function Add-FAUsertoIntCliSecGroups {
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

#This command removes a user from unified groups

function Remove-FAUserfromGroup{
    [CmdletBinding()]


    $user = read-host "Please specify user to be removed from group"
    Write-Host
    $groups = get-unifiedgroup

    foreach ($group in $groups) {

        Write-Output "Removing from $($group.Alias)" 

        Remove-UnifiedGroupLinks -Identity $group.Alias -Links $user -LinkType Members -Confirm:$false
    }

    Write-Host "$user has now been removed from groups" -ForegroundColor Green

}
