<#
.Synopsis
Adds new O365 Users to tenant using Script User provided input values.
.Description
Creates new Office 365 User in tenant. Users are created via Script User input values for Display Name, User Name, etc.
Should the user already exist, then the the script will change the UserPrincipalName to allow creation of the new user. 
Following this, the script user will then be prompted to confirm that they wish for the user to be created, and can cancel if desired.
Following creation of the user, password setup and license assignment will still need to be undertaken via the Admin Centre.

.Example
New-MsolUser

Adds new User to Microsoft Azure Directory
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
 
$UserPrincipalName = $FirstName + ".$LastName" + "@$Domain"

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

$Proceed = $null
$Proceed = Read-Host "Proceed with user creation - Y/N?"

if ($Proceed -ieq 'Y') {
    New-MsolUser -DisplayName $DisplayName -FirstName $FirstName -LastName $LastName -UserPrincipalName $UserPrincipalName

    Get-MsolUser -UserPrincipalName $UserPrincipalName

    Write-Host "User $Displayname will now been created" -ForegroundColor Green

    #The account should now be appearing under Active Users in the O365 Admin Centre

}
else {
    Write-Host "Process cancelled" -ForegroundColor Yellow
}
