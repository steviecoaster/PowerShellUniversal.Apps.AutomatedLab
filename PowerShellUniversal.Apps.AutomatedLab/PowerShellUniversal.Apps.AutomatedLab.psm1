function New-UDAutomatedLabApp {
    <#
    .SYNOPSIS
    Creates a new AutomatedLab management app.
    
    .DESCRIPTION
    Creates a new AutomatedLab management app for PowerShell Universal.
    #>

    # Load all page scripts
    Write-Output $PSScriptRoot
    $DashboardPath = Join-Path $PSScriptRoot -ChildPath 'dashboards\AutomatedLab'
    Get-ChildItem (Join-Path $DashboardPath -ChildPath 'pages') -Recurse -Filter *.ps1 | Foreach-Object {
        . $_.FullName
    }

    # Execute the main app script and return the app
    $AppScript = Join-Path $DashboardPath 'AutomatedLab.ps1'
    & $AppScript
}