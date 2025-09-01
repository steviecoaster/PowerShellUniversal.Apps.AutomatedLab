function New-UDAutomatedLabApp {
    <#
    .SYNOPSIS
    Creates a new AutomatedLab management app.
    
    .DESCRIPTION
    Creates a new AutomatedLab management app for PowerShell Universal.
    #>

    # Load all page scripts
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
                    $config.Add('Lab', $_.Name)
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
        [Parameter(Mandatory, ValueFromPipeline)]
        [Hashtable]
        $InputObject
    )

    process {
        $newHash = @{}

        $newHash.Definition = $InputObject['Definition']
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

function Get-PSULabInfo {
    <#
    .SYNOPSIS
    Gets virtual machine information for a specific lab using PowerShell Universal context
    
    .DESCRIPTION
    This function imports an AutomatedLab by name and returns information about each machine
    including the name, processor count, memory, and operating system. This version is optimized
    for use within PowerShell Universal dashboards.
    
    .PARAMETER LabName
    The name of the lab to import and analyze.
    
    .EXAMPLE
    Get-PSULabInfo -LabName "MyTestLab"
    
    .NOTES
    This function requires the AutomatedLab module to be installed and available.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LabName
    )
    
    try {
        Write-Verbose "Importing lab: $LabName"
        # Import the lab without validation to speed up the process
        Import-Lab -Name $LabName -NoValidation -NoDisplay | Out-Null

        $machines = Get-LabVM
        $status = Get-LabVMStatus -AsHashTable
        
        if (-not $machines) {
            Write-Warning "No machines found in lab '$LabName'"
            return @()
        }
        
        $labInfo = foreach ($machine in $machines) {
            [PSCustomObject]@{
                Name            = $machine.Name
                ProcessorCount  = $machine.Processors
                Memory          = $machine.Memory
                OperatingSystem = $machine.OperatingSystem.OperatingSystemName
                MemoryGB        = [Math]::Round($machine.Memory / 1GB, 2)
                Status          = $status[$machine.Name]
            }
        }
        
        Write-Verbose "Retrieved information for $($labInfo.Count) machines"
        return $labInfo
    }
    catch {
        Write-Error "Failed to import lab '$LabName': $($_.Exception.Message)"
        return @()
    }
}

function Get-LabInfo {
    <#
    .SYNOPSIS
    Imports a lab by name and returns basic information about the lab machines.
    
    .DESCRIPTION
    This function imports an AutomatedLab by name and returns information about each machine
    including the name, processor count, memory, and operating system.
    
    .PARAMETER LabName
    The name of the lab to import and analyze.
    
    .EXAMPLE
    Get-LabInfo -LabName "MyTestLab"
    
    .EXAMPLE
    Get-LabInfo "MyTestLab" | Format-Table -AutoSize
    
    .NOTES
    This function requires the AutomatedLab module to be installed and available.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                try {
                    $availableLabs = Get-Lab -List
                    $availableLabs | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                    }
                }
                catch {
                    @()
                }
            })]
        [string]$LabName
    )
    
    try {

        Write-Verbose "Importing lab: $LabName"
        # Nothing nulls this output. Resistence is futile. Thankfully this usecase will never see it so whatever.
        Import-Lab -Name $LabName -NoValidation | Out-Null

        $machines = Get-LabVM
        $status = Get-LabVMStatus -AsHashTable
        if (-not $machines) {
            Write-Warning "No machines found in lab '$LabName'"
            return
        }
        
        $labInfo = foreach ($machine in $machines) {
            [PSCustomObject]@{
                Name            = $machine.Name
                ProcessorCount  = $machine.Processors
                Memory          = $machine.Memory
                OperatingSystem = $machine.OperatingSystem.OperatingSystemName
                MemoryGB        = [Math]::Round($machine.Memory / 1GB, 2)
                Status          = $status[$machine.Name]
            }
        }
        
        Write-Verbose "Retrieved information for $($labInfo.Count) machines"
        return $labInfo
    }
    catch {
        Write-Error "Failed to import lab '$LabName': $($_.Exception.Message)"
        throw
    }
}

function New-AutomatedLabDefinitionScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]
        $LabData
    )
    
    process {
        $script = @"
# AutomatedLab Definition: $($LabData.LabName)
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Import-Module AutomatedLab

New-LabDefinition -Name '$($LabData.LabName)' -DefaultVirtualizationEngine HyperV

"@

        # Add virtual switches
        foreach ($network in $LabData.Networks) {
            switch ($network.SwitchType) {
                'DefaultSwitch' {
                    $script += "Add-LabVirtualNetworkDefinition -Name 'Default Switch'`n"
                }
                'Internal' {
                    $script += "Add-LabVirtualNetworkDefinition -Name '$($network.Name)' -AddressSpace '$($network.Subnet)'"
                    if ($network.Gateway) { 
                        $script += " -HyperVProperties @{ SwitchType = 'Internal' }" 
                    }
                    $script += "`n"
                }
                'External' {
                    $script += "Add-LabVirtualNetworkDefinition -Name '$($network.Name)' -HyperVProperties @{ SwitchType = 'External'; AdapterName = '$($network.PhysicalAdapter)' }`n"
                }
            }
        }

        $script += "`n"

        # Add VMs
        foreach ($vm in $LabData.VMs) {
            $script += "Add-LabMachineDefinition -Name '$($vm.Name)' -OperatingSystem '$($vm.OS)' -Memory $($vm.RAM)GB -Processors $($vm.CPU)"
        
            if ($vm.NetworkAdapters -and $vm.NetworkAdapters.Count -gt 0) {
                $adapters = $vm.NetworkAdapters | ForEach-Object {
                    $adapterDef = "New-LabNetworkAdapterDefinition -VirtualSwitch '$($_.VirtualSwitch)'"
                    if ($_.InterfaceName) {
                        $adapterDef += " -InterfaceName '$($_.InterfaceName)'"
                    }
                    if ($_.IpAddress -and ![string]::IsNullOrEmpty($_.IpAddress)) {
                        $adapterDef += " -IpAddress '$($_.IpAddress)'"
                    }
                    if ($_.UseDhcp -eq $false -and $_.IpAddress) {
                        # Static IP configuration - don't add UseDhcp parameter as it defaults to false when IpAddress is specified
                    }
                    else {
                        # DHCP configuration
                        $adapterDef += " -UseDhcp"
                    }
                    $adapterDef
                }
                $script += " -NetworkAdapter @($($adapters -join ', '))"
            }
            $script += "`n"
        }

        $script += "`n"

        # Add custom role assignments
        $hasCustomRoles = $false
        foreach ($vm in $LabData.VMs) {
            if ($vm.CustomRoles -and $vm.CustomRoles.Count -gt 0) {
                $hasCustomRoles = $true
                break
            }
        }

        if ($hasCustomRoles) {
            $script += "# Apply custom roles to VMs`n"
            foreach ($vm in $LabData.VMs) {
                if ($vm.CustomRoles -and $vm.CustomRoles.Count -gt 0) {
                    foreach ($role in $vm.CustomRoles) {
                        $script += "Invoke-LabCommand -ComputerName '$($vm.Name)' -CustomRoleName $role `n"
                    }
                }
            }
        }

        $script += @"

Install-Lab

"@

        return $script
    }
}

function New-AutomatedLabISO {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $ISOFile
    )

    end {
        $LabSources = Get-LabSourcesLocation -Local
        $ISOFolder = Join-Path $LabSources -ChildPath 'ISOs'
        try {
            Copy-Item $ISOFile -Destination $ISOFolder -ErrorAction Stop
            Show-UDToast -Message "$ISOFile added to $ISOFolder successfully!"
        }
        catch {
            Show-UDToast -Message "$ISOFile upload failed!"
        }   
    }
}

function Start-PSULab {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $LabName
    )

    end {
        Start-Lab -Name $LabName -ErrorAction SilentlyContinue
    }
}

function Start-SingleVM {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $LabVM
    )

    end {
        Start-LWHypervVM -ComputerName $LabVM -TimeoutInMinutes 5
    }
}

function Stop-PSULab {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $LabName
    )

    end {
        Stop-Lab -Name $LabName -ErrorAction SilentlyContinue
    }
}

function Stop-SingleVM {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $LabVM
    )

    end {
        Stop-LWHypervVM -ComputerName $LabVM -TimeoutInMinutes 5
    }
}


New-PSUScript -Module 'PowerShellUniversal.Apps.AutomatedLab' -Command 'Start-Lab' -Environment 'PowerShell 7'