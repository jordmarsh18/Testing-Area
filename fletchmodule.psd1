@{
    ModuleVersion = '1.0.0'
    NestedModules = @(
      '.\tools\Add-FAUsertoGroup.ps1', 
      '.\tools\New-FAPnPSite.ps1', 
      '.\tools\New-FAUnifiedGroup.ps1', 
      '.\tools\New-FAUser.ps1'
    )
    FunctionsToExport = @('*')
  }