<#
.Synopsis
Adds new O365 Users to tenant using Script User provided input values.
.Description
This script creates new users in O365. Users are created using input values provided by the script user for Username, Displayname, etc.
Should the user account already be set up on the tenant, then the username will be altered by the script to allow creation of a new account. 
However, following this the script user will still be prompted to confirm that they want to create the account, and can cancel if desired.
Following the creation of the account, you will still be required to log in and set up a password for the new user, as well as add an appropriate license for them.
.Example
New-MsolUser

This creates a new O365 user on the tenant.
#>


$Credential = Get-Credential
Connect-MsolService -Credential $Credential

$Firstname = Read-Host "Enter the First Name"
Write-Host
$LastName = Read-Host "Enter the Last Name"
Write-Host
$Displayname = $Firstname + " " + $LastName

#Acquire domain from Get-MSolDomain command and filter out onmicrosoft.com
#If a domain is not found, it will revert to the onmicrosoft.com domain

$Domain = Get-MsolDomain | Where-Object {($_.Name -notmatch ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name
if (-not $Domain) {$Domain = Get-MsolDomain | Where-Object {($_.Name -match ".onmicrosoft.com") -and ($_.Status -eq "Verified") -and ($_.Authentication -eq "Managed")} | Select-Object -ExpandProperty Name}
 
$UserPrincipalName = $FirstName + "." + $LastName + "@$Domain"

Write-Host "First Name: $Firstname"
Write-Host "Last Name: $LastName"
Write-Host "DisplayName: $Displayname"
Write-Host "UserName: $UserPrincipalName"
Write-Host "Domain: $Domain"

#Check if an O365 account already exists. If so, account creation process will cease.

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
Start-Sleep 2

Write-Host "____________________________________________________"
Write-Host
Write-Host "First Name: $Firstname"
Write-Host "Last Name: $LastName"
Write-Host "DisplayName: $Displayname"
Write-Host "UserName: $UserPrincipalName"
Write-Host "Domain: $Domain"
Write-Host 

Write-Host "Thank you - O365 Account will now be created" -ForegroundColor Green

$Proceed = $null
$Proceed = Read-Host "Continue - Y/N?"

if ($Proceed -ieq 'Y') {
    New-MsolUser -DisplayName $DisplayName -FirstName $FirstName -LastName $LastName -UserPrincipalName $UserPrincipalName
    Start-Sleep 2

    Get-MsolUser -UserPrincipalName $UserPrincipalName

    Write-Host "Process complete. $Displayname has now been created" -ForegroundColor Green

    #The account should now be appearing under Active Users in the O365 Admin Centre

}
else {
    Write-Host "User has cancelled process" -ForegroundColor Yellow
}
