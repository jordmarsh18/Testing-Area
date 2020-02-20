#Removes old views and recreates them but with added queries.
#Add-PnPView occasionally needs to be wrapped in a $ variable for some reason, otherwise the command doesn't work?

$sites = Get-UnifiedGroup -Filter {[Alias] -like "BSS-*"}

foreach ($site in $sites) {
    
Write-Output "Getting list from site $site"

Connect-PnPOnline -Url $site.SharePointSiteUrl -UseWebLogin


$list = "Employees"
Write-Output "Removing Views from $list section on site $site"
Remove-PnPView -List "Employees" -Identity "Active" -Force
Remove-PnPView -List "Employees" -Identity "Ex-Employee" -Force


Write-Output "Adding Active View to $list section on site $site"

$viewTitle = "Active"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Active</Value></Eq></Where>"

$Add1 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery -Fields $viewFields

Write-Output "Adding Ex-Employee View to $list section on site $site"
$list = "Employees"
$viewTitle = "Ex-Employee"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery2 = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Ex-Employee</Value></Eq></Where>"

$Add2 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery2 -Fields $viewFields

}#end foreach site
