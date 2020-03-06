#Below script used for FA Employee Folders - Creates Active/Ex-Employee Views, filtering on the Employee Status column, and also displays folder items alphabetically.


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
$viewQuery = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Active</Value></Eq></Where><OrderBy><FieldRef Name='LinkFilename' Ascending='TRUE'/></OrderBy>"


$Add1 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery -Fields $viewFields -rowlimit 5000 

Write-Output "Adding Ex-Employee View to $list section on site $($site.Alias)"
$viewTitle = "Ex-Employee"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery2 = "<Where><Eq><FieldRef Name = 'EmployeeStatus' /><Value Type = 'Choice'>Ex-Employee</Value></Eq></Where><OrderBy><FieldRef Name='LinkFilename' Ascending='TRUE'/></OrderBy>"

$Add2 = Add-PnPView -List $list -Title $viewTitle -Query $viewQuery2 -Fields $viewFields -rowlimit 5000



Write-Output "Adding All Documents View to $list section on site $($site.Alias)"
$viewTitle = "All Documents"
$viewFields = @("Type", "Name", "Enterprise Keywords", "Modified", "Modified By", "Occupation", "Employee Status")
$viewQuery3 = "<OrderBy><FieldRef Name='LinkFilename' Ascending='TRUE'/></OrderBy>"

$Add3 = Add-PnPView -List $list -Title $viewTitle -Fields $viewFields -Query $viewQuery3 -rowlimit 5000 -SetasDefault


}#end foreach site
