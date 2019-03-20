<#Possibly replace New-FAUser
This command creates a new Fletcher Associates user, which can be of the member or guest usertype. If it's the former, 
then onboarding can be completed by using the other follow up scripts/functions on this github account - e.g, Add-FAUsertoGroup, etc.
If it's the latter, then the command set also creates a PnP group and role definition aimed at external users, and adds
the guest user to a SharePoint list which details all external users currently with guest access.
#>

#New Fletcher Associates User - Member AND Guest:

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
