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

function Get-PSULabConfiguration {
    <#
    .SYNOPSIS
    Returns lab configuration objects
    
    .DESCRIPTION
    Returns all lab configurations when no Name is specified, or a specific configuration when Name is provided.
       
    .PARAMETER Name
    The name of the specific configuration to return. If not specified, all configurations are returned.
    
    .EXAMPLE
    Get-AllLabConfigurations
    
    Returns all available lab configurations.
    
    .EXAMPLE
    Get-AllLabConfigurations -Name Example
    
    Returns the specific configuration named 'Example'.
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

                $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
                if (Test-Path $configPath) {
                    Get-ChildItem -Path $configPath -Directory | Where-Object {
                        $_.Name -like "$wordToComplete*"
                    } | ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
                    }
                }
            })]
        [String]
        $Name
    )

    end {
        if ($Name) {
            $config = Import-Configuration -Name $Name -CompanyName $env:USERNAME
            $config['Lab'] = $Name
            $config | Split-Configuration
        }
        else {
            $configPath = Join-Path $env:LocalAppData -ChildPath "powershell\$env:USERNAME"
            if (Test-Path $configPath) {
                Get-ChildItem -Path $configPath -Directory | ForEach-Object {
                    $config = Import-Configuration -Name $_.Name -CompanyName $env:USERNAME
                    $config.Add('Lab',$_.Name)
                    $config | Split-Configuration
                }
            }
        }
    }
}

function Split-Configuration {
    <#
    .SYNOPSIS
    Expands parameter hashtable from a configuration and adds indiviual properties to the parent object
    
    .PARAMETER InputObject
    The configuration  hashtable to split
    
    .EXAMPLE
    Split-Configuration -InputObject $configuration

    .EXAMPLE
    Get-LabConfiguration | Split-Configuration

    .EXAMPLE
    Get-PSULabConfiguration -Name Demo | Split-Configuration
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [Hashtable]
        $InputObject
    )

    process {
        $newHash = @{}

        $newHash.Defintion = $InputObject['Definition']
        $newHash.Lab = $InputObject['Lab']
        $parameters = $InputObject['Parameters']
        $parameters.GetEnumerator() | ForEach-Object {
            if ($_.Key -ne 'Name') {
                $newHash.Add($_.Key, $_.Value)
            }
        }

        [PSCustomObject]$newHash
    }
}