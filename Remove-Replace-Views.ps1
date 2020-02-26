$sites = Get-UnifiedGroup -Filter {[Alias] -like "BSS-*"}

foreach ($site in $sites) {
    
Write-Output "Getting list from site $site"

Connect-PnPOnline -Url $site.SharePointSiteUrl -UseWebLogin


$list = "Employees"
Write-Output "Removing Views from $list section on site $($site.Alias)"
Remove-PnPView -List "Employees" -Identity "Active" -Force
Remove-PnPView -List "Employees" -Identity "Ex-Employee" -Force
Remove-PnPView -List "Employees" -Identity "All Documents" -Force

Write-Output "Adding Active View to $list section on site $($site.Alias)"
$viewTitle = "Active"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Active</Value></Eq></Where>"


$Add1 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery -Fields $viewFields -rowlimit 5000 

Write-Output "Adding Ex-Employee View to $list section on site $($site.Alias)"
$viewTitle = "Ex-Employee"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery2 = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Ex-Employee</Value></Eq></Where>"

$Add2 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery2 -Fields $viewFields -rowlimit 5000



Write-Output "Adding All Documents View to $list section on site $($site.Alias)"
$viewTitle = "All Documents"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")

$Add3 = Add-PnPView -List $list -Title $viewTitle -Fields $viewFields -rowlimit 5000 -SetasDefault


}#end foreach site
