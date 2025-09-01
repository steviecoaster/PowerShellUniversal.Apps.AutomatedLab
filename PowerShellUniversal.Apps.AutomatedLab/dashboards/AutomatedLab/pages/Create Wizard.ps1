$WizardPage = New-UDPage -Url '/Create-Lab' -Name 'Create A Lab' -Content {
# Force reset of session variables on page load
    $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    # Add Default Switch automatically
    $defaultSwitch = @{
        Name            = "Default Switch"
        SwitchType      = "DefaultSwitch"
        Subnet          = "Default Switch NAT"
        IsDefaultSwitch = $true
    }
    $Session:Networks.Add([PSCustomObject]$defaultSwitch)
    
    $Session:VMs = @()
    $Session:AvailableOS = @()
    $Session:OSLoaded = $false
    $Session:OSLoadError = $false
    $Session:AvailableNetworkAdapters = @()
    $Session:AdaptersLoaded = $false
    $Session:LabName = ""
    $Session:LabDescription = ""
    $Session:GeneratedScript = ""

    New-UDContainer -Content {
        New-UDTypography -Text "AutomatedLab Creation Wizard" -Variant h3 -Align center
        New-UDDivider

        # Loading component while fetching OS and network adapter data
        New-UDDynamic -Id "MainContent" -Content {
            if ((-not $Session:OSLoaded -and -not $Session:OSLoadError) -or -not $Session:AdaptersLoaded) {
                New-UDCard -Content {
                    New-UDStack -Direction column -AlignItems center -Spacing 3 -Content {
                        New-UDProgress -Circular -Color primary -Size medium
                        New-UDTypography -Text "Loading lab configuration data..." -Variant h6 -Align center
                        New-UDTypography -Text "Please wait while we fetch available operating systems and network adapters." -Variant body2 -Align center -Style @{ 'opacity' = '0.7' }
                    }
                } -Style @{ 'padding' = '40px'; 'text-align' = 'center' }
            }
            elseif ($Session:OSLoadError -and (-not $Session:AvailableOS -or $Session:AvailableOS.Count -eq 0)) {
                # Show error message when no OS are available
                New-UDCard -Content {
                    New-UDStack -Direction column -AlignItems center -Spacing 3 -Content {
                        New-UDIcon -Icon exclamationTriangle -Size "2x" -Color warning
                        New-UDTypography -Text "No Operating Systems Available" -Variant h5 -Align center
                        New-UDTypography -Text "No ISO files were found in your AutomatedLab ISO directory." -Variant body1 -Align center
                        New-UDTypography -Text "Please add ISO files to your ISO directory before creating lab definitions." -Variant body2 -Align center -Style @{ 'opacity' = '0.8' }
                        New-UDButton -Text "Open ISO Management" -Color primary -OnClick {
                            # Navigate to ISO management page if available
                            Show-UDToast -Message "Please use the ISO Management page to add operating system ISO files."
                        }
                    }
                } -Style @{ 'padding' = '40px'; 'text-align' = 'center' }
            }
            else {
                # Stepper Component (only shown after OS data is loaded)
                New-UDStepper -Id "LabBuilderStepper" -OnFinish {
                } -Steps {
        
                    # Step 1: Lab Information
                    New-UDStep -OnLoad {
                        New-UDCard -Title "Lab Configuration" -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDTextbox -Id "LabName" -Label "Lab Name" -Placeholder "Enter lab name (e.g., 'Active Directory Lab')" -FullWidth -Value $Session:LabName -OnChange {
                                        $Session:LabName = $EventData
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDTextbox -Id "LabDescription" -Label "Lab Description (Optional)" -Placeholder "Brief description of this lab environment" -Multiline -Rows 3 -FullWidth -Value $Session:LabDescription -OnChange {
                                        $Session:LabDescription = $EventData
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDAlert -Severity info -Text "Start by giving your lab a name and description. This helps identify the purpose and scope of your lab environment."
                                }
                            }
                        }
                    } -Label "Lab Info"
        
                    # Step 2: Virtual Switch Configuration
                    New-UDStep -OnLoad {
                        New-UDCard -Title "Virtual Switch Configuration" -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDAlert -Severity info -Text "Configure virtual switches (networks) for your lab. AutomatedLab supports Internal, External, and Default Switch configurations."
                                }
                    
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDTextbox -Id "NetworkName" -Label "Virtual Switch Name" -Placeholder "e.g., Internal, External, Management"
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDSelect -Id "NetworkSwitchType" -Label "Switch Type" -Option {
                                        New-UDSelectOption -Name "Default Switch (NAT - Internet Access)" -Value "DefaultSwitch"
                                        New-UDSelectOption -Name "Internal (Isolated Network)" -Value "Internal"
                                        New-UDSelectOption -Name "External (Bridged to Physical Adapter)" -Value "External"
                                    } -OnChange {
                                        $switchType = $EventData
                                        if ($switchType -eq "Internal") {
                                            Set-UDElement -Id "InternalFields" -Properties @{ style = @{ display = "block" } }
                                            Set-UDElement -Id "ExternalFields" -Properties @{ style = @{ display = "none" } }
                                        }
                                        elseif ($switchType -eq "External") {
                                            Set-UDElement -Id "InternalFields" -Properties @{ style = @{ display = "none" } }
                                            Set-UDElement -Id "ExternalFields" -Properties @{ style = @{ display = "block" } }
                                        }
                                        else {
                                            Set-UDElement -Id "InternalFields" -Properties @{ style = @{ display = "none" } }
                                            Set-UDElement -Id "ExternalFields" -Properties @{ style = @{ display = "none" } }
                                        }
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDButton -Text "Add Virtual Switch" -Color primary -OnClick {
                                        $networkName = (Get-UDElement -Id "NetworkName").value
                                        $switchType = (Get-UDElement -Id "NetworkSwitchType").value
                            
                                        if ($networkName -and $switchType) {
                                            # Check for duplicates
                                            if ($Session:Networks | Where-Object { $_.Name -eq $networkName }) {
                                                Show-UDToast -Message "Virtual switch name '$networkName' already exists!"
                                                return
                                            }
                                
                                            $newNetwork = @{
                                                Name       = $networkName
                                                SwitchType = $switchType
                                            }
                                
                                            if ($switchType -eq "DefaultSwitch") {
                                                $newNetwork['Subnet'] = 'Default Switch NAT'
                                                $newNetwork['IsDefaultSwitch'] = $true
                                            }
                                            elseif ($switchType -eq "Internal") {
                                                $subnet = (Get-UDElement -Id "NetworkSubnet").value
                                                if (-not $subnet) {
                                                    Show-UDToast -Message "Address space is required for internal switches"
                                                    return
                                                }
                                                $newNetwork['Subnet'] = $subnet
                                                $gateway = (Get-UDElement -Id "NetworkGateway").value
                                                if ($gateway) {
                                                    $newNetwork['Gateway'] = $gateway
                                                }
                                            }
                                            elseif ($switchType -eq "External") {
                                                $physicalAdapter = (Get-UDElement -Id "PhysicalAdapter").value
                                                if (-not $physicalAdapter) {
                                                    Show-UDToast -Message "Physical adapter name is required for external switches"
                                                    return
                                                }
                                                $newNetwork['PhysicalAdapter'] = $physicalAdapter
                                                $newNetwork['Subnet'] = 'Bridged to Physical Network'
                                            }
                                
                                            if (-not $Session:Networks) { $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new() }
                                            $Session:Networks.Add([PSCustomObject]$newNetwork) 
                                            Sync-UDElement -Id "NetworkList"
                                
                                            # Clear form
                                            Set-UDElement -Id "NetworkName" -Properties @{ value = "" }
                                            Set-UDElement -Id "NetworkSubnet" -Properties @{ value = "" }
                                            Set-UDElement -Id "NetworkGateway" -Properties @{ value = "" }
                                            Set-UDElement -Id "PhysicalAdapter" -Properties @{ value = "" }
                                        }
                                        else {
                                            Show-UDToast -Message "Please provide Virtual Switch Name and Switch Type"
                                        }
                                    }
                                }
                    
                                # Internal Network Fields
                                New-UDGrid -Item -ExtraSmallSize 12 -Id "InternalFields" -Content {
                                    New-UDGrid -Container -Content {
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                            New-UDTextbox -Id "NetworkSubnet" -Label "Address Space (CIDR)" -Placeholder "e.g., 192.168.1.0/24"
                                        }
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                            New-UDTextbox -Id "NetworkGateway" -Label "Gateway IP (Optional)" -Placeholder "e.g., 192.168.1.1"
                                        }
                                    }
                                } -Style @{ display = "none" }
                    
                                # External Network Fields
                                New-UDGrid -Item -ExtraSmallSize 12 -Id "ExternalFields" -Content {
                                    New-UDGrid -Container -Content {
                                        New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                            New-UDDynamic -Id "PhysicalAdapterSelect" -Content {
                                                if ($Session:AvailableNetworkAdapters -and $Session:AvailableNetworkAdapters.Count -gt 0) {
                                                    New-UDSelect -Id "PhysicalAdapter" -Label "Physical Network Adapter" -Option {
                                                        foreach ($adapter in $Session:AvailableNetworkAdapters) {
                                                            New-UDSelectOption -Name "$($adapter.Name) - $($adapter.InterfaceDescription)" -Value $adapter.Name
                                                        }
                                                    }
                                                }
                                                else {
                                                    New-UDSelect -Id "PhysicalAdapter" -Label "Physical Network Adapter" -Option {
                                                        New-UDSelectOption -Name "Loading network adapters..." -Value "" -Disabled
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } -Style @{ display = "none" }
                            }
                        }
            
                        New-UDDynamic -Id "NetworkList" -Content {
                            $networkCount = ($Session:Networks | Measure-Object).Count
                            if ($Session:Networks -and $networkCount -gt 0) {
                                New-UDCard -Title "Defined Virtual Switches ($networkCount)" -Content {
                                    New-UDTable -Data $Session:Networks -Columns @(
                                        New-UDTableColumn -Property "Name" -Title "Switch Name"
                                        New-UDTableColumn -Property "SwitchType" -Title "Type" -Render {
                                            switch ($EventData.SwitchType) {
                                                "DefaultSwitch" { "Default Switch" }
                                                "Internal" { "Internal" }
                                                "External" { "External" }
                                                default { $EventData.SwitchType }
                                            }
                                        }
                                        New-UDTableColumn -Property "Subnet" -Title "Address Space/Network"
                                        New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                            New-UDStack -Direction row -Spacing 1 -Content {
                                                New-UDButton -Text "Remove" -Size small -OnClick {
                                                    $selectedNetwork = $EventData.Name
                                                    # Properly remove from List object
                                                    $itemToRemove = $Session:Networks | Where-Object { $_.Name -eq $selectedNetwork }
                                                    if ($itemToRemove) {
                                                        $Session:Networks.Remove($itemToRemove)
                                                    }
                                                    Sync-UDElement -Id "NetworkList"
                                                } -Color error -Icon (New-UDIcon -Icon trash)
                                            }
                                           
                                        }
                                    )
                                }
                            }
                            else {
                                New-UDAlert -Severity info -Text "Define at least one virtual switch for your lab environment."
                            }
                        }
                    } -Label "Virtual Switches"
        
                    # Step 3: Virtual Machine Configuration
                    New-UDStep -OnLoad {
                        # Basic VM Information Card
                        New-UDCard -Title "Basic VM Information" -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDAlert -Severity info -Text "Configure the basic properties for your virtual machine."
                                } -Style @{ 'margin-bottom' = '16px' }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDTextbox -Id "VMName" -Label "VM Name" -Placeholder "e.g., DC01, WEB01, CLIENT01" -FullWidth
                                } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDSelect -Id "VMSize" -Label "VM Size" -FullWidth -Option {
                                        New-UDSelectOption -Name "Small - 2 CPU, 4GB RAM" -Value "Small"
                                        New-UDSelectOption -Name "Medium - 4 CPU, 8GB RAM" -Value "Medium"
                                        New-UDSelectOption -Name "Large - 8 CPU, 16GB RAM" -Value "Large"
                                        New-UDSelectOption -Name "Custom - Specify CPU/RAM" -Value "Custom"
                                    } -OnChange {
                                        if ($EventData -eq "Custom") {
                                            Set-UDElement -Id "CustomVMSpecs" -Properties @{ style = @{ display = "block" } }
                                        }
                                        else {
                                            Set-UDElement -Id "CustomVMSpecs" -Properties @{ style = @{ display = "none" } }
                                        }
                                    }
                                } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDDynamic -Id "OSSelect" -Content {
                                        if ($Session:AvailableOS -and $Session:AvailableOS.Count -gt 0) {
                                            New-UDSelect -Id "VMOS" -Label "Operating System" -FullWidth -Option {
                                                foreach ($os in $Session:AvailableOS) {
                                                    New-UDSelectOption -Name $os -Value $os
                                                }
                                            }
                                        }
                                        elseif ($Session:OSLoadError) {
                                            # Show error message when no OS are available
                                            New-UDAlert -Severity error -Text "No operating systems available. Please add ISO files to your AutomatedLab ISO directory before creating VMs."
                                        }
                                        else {
                                            # Still loading
                                            New-UDSelect -Id "VMOS" -Label "Operating System" -FullWidth -Option {
                                                New-UDSelectOption -Name "Loading operating systems..." -Value "" -Disabled
                                            }
                                        }
                                    }
                                } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                
                                # Custom VM Specifications (conditionally shown)
                                New-UDGrid -Item -ExtraSmallSize 12 -Id "CustomVMSpecs" -Content {
                                    New-UDCard -Content {
                                        New-UDTypography -Text "Custom VM Specifications" -Variant subtitle2 -Style @{ 'margin-bottom' = '12px' }
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                                New-UDTextbox -Id "CustomCPU" -Label "CPU Cores" -Placeholder "e.g., 4" -FullWidth -Type number
                                            } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                                New-UDTextbox -Id "CustomRAM" -Label "RAM (GB)" -Placeholder "e.g., 8" -FullWidth -Type number
                                            } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                        } -Spacing 2
                                    } -Style @{ 'background-color' = 'rgba(0, 123, 255, 0.05)'; 'border' = '1px solid rgba(0, 123, 255, 0.2)' }
                                } -Style @{ display = "none"; 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                            } -Spacing 2
                        } -Style @{ 'margin-bottom' = '16px' }

                        # Custom Roles Assignment Card
                        New-UDCard -Title "Custom Roles (Optional)" -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDAlert -Severity info -Text "Assign custom roles to this VM. Roles will be applied after the VM is created."
                                } -Style @{ 'margin-bottom' = '16px' }
                                
                                # Role Selection Row
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 8 -Content {
                                    New-UDDynamic -Id "RoleSelect" -Content {
                                        try {
                                            $availableRoles = Get-CustomRole
                                            if ($availableRoles -and $availableRoles.Count -gt 0) {
                                                New-UDSelect -Id "VMRole" -Label "Available Custom Roles" -FullWidth -Option {
                                                    foreach ($role in $availableRoles) {
                                                        New-UDSelectOption -Name $role -Value $role
                                                    }
                                                }
                                            }
                                            else {
                                                New-UDSelect -Id "VMRole" -Label "Available Custom Roles" -FullWidth -Option {
                                                    New-UDSelectOption -Name "No custom roles available" -Value "" -Disabled
                                                }
                                            }
                                        }
                                        catch {
                                            New-UDSelect -Id "VMRole" -Label "Available Custom Roles" -FullWidth -Option {
                                                New-UDSelectOption -Name "Error loading roles" -Value "" -Disabled
                                            }
                                        }
                                    }
                                } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDButton -Text "Add Role" -Color secondary -FullWidth -OnClick {
                                        $selectedRole = (Get-UDElement -Id "VMRole").value
                                        
                                        if ($selectedRole) {
                                            # Initialize session variable for current VM roles if it doesn't exist
                                            if (-not $Session:CurrentVMRoles) { $Session:CurrentVMRoles = @() }
                                            
                                            # Check if role is already added
                                            if ($Session:CurrentVMRoles -contains $selectedRole) {
                                                Show-UDToast -Message "Role '$selectedRole' is already assigned to this VM"
                                                return
                                            }
                                            
                                            $Session:CurrentVMRoles = @($Session:CurrentVMRoles) + $selectedRole
                                            Sync-UDElement -Id "VMRoleList"
                                        }
                                        else {
                                            Show-UDToast -Message "Please select a role to add"
                                        }
                                    } -Icon (New-UDIcon -Icon plus)
                                } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                
                                # Current VM Roles Display
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDDynamic -Id "VMRoleList" -Content {
                                        if ($Session:CurrentVMRoles -and $Session:CurrentVMRoles.Count -gt 0) {
                                            New-UDCard -Content {
                                                New-UDTypography -Text "Assigned Roles for Current VM:" -Variant subtitle2 -Style @{ 'margin-bottom' = '8px' }
                                                New-UDTable -Data ($Session:CurrentVMRoles | ForEach-Object { 
                                                    [PSCustomObject]@{ 
                                                        RoleName = $_ 
                                                    } 
                                                }) -Columns @(
                                                    New-UDTableColumn -Property "RoleName" -Title "Role Name"
                                                    New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                                        New-UDStack -Direction row -Spacing 1 -Content {
                                                            New-UDButton -Text "Remove" -Size small -Color error -OnClick {
                                                                $roleToRemove = $EventData.RoleName
                                                                $Session:CurrentVMRoles = $Session:CurrentVMRoles | Where-Object { $_ -ne $roleToRemove }
                                                                Sync-UDElement -Id "VMRoleList"
                                                            } -Icon (New-UDIcon -Icon trash)
                                                        }
                                                    }
                                                ) -Dense -Size small
                                            } -Style @{ 'background-color' = 'rgba(33, 150, 243, 0.05)'; 'border' = '1px solid rgba(33, 150, 243, 0.2)' }
                                        }
                                        else {
                                            New-UDAlert -Severity info -Text "No custom roles assigned. Roles are optional and can be added after VM creation."
                                        }
                                    }
                                } -Style @{ 'margin-top' = '16px' }
                            } -Spacing 2
                        } -Style @{ 'margin-bottom' = '16px' }

                        # Network Configuration Card
                        New-UDDynamic -Id "VMNetworkSelect" -Content {
                            $networkCount = ($Session:Networks | Measure-Object).Count
                            if ($Session:Networks -and $networkCount -gt 0) {
                                New-UDCard -Title "Network Configuration" -Content {
                                    New-UDGrid -Container -Content {
                                        New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                            New-UDAlert -Severity info -Text "Configure network adapters to connect this VM to your virtual switches. At least one adapter is required."
                                        } -Style @{ 'margin-bottom' = '16px' }
                                        
                                        # NIC Configuration Row
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                            New-UDSelect -Id "VMNetwork" -Label "Virtual Switch" -FullWidth -Option {
                                                foreach ($network in $Session:Networks) {
                                                    New-UDSelectOption -Name "$($network.Name) ($($network.Subnet))" -Value $network.Name
                                                }
                                            }
                                        } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Content {
                                            New-UDSelect -Id "NICUseDHCP" -Label "IP Assignment" -FullWidth -Option {
                                                New-UDSelectOption -Name "DHCP (Automatic)" -Value "DHCP"
                                                New-UDSelectOption -Name "Static IP" -Value "Static"
                                            } -DefaultValue "DHCP" -OnChange {
                                                if ($EventData -eq "Static") {
                                                    Set-UDElement -Id "StaticIPField" -Properties @{ style = @{ display = "block" } }
                                                }
                                                else {
                                                    Set-UDElement -Id "StaticIPField" -Properties @{ style = @{ display = "none" } }
                                                }
                                            }
                                        } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Content {
                                            New-UDButton -Text "Add Network Adapter" -Color secondary -FullWidth -OnClick {
                                                $selectedNetwork = (Get-UDElement -Id "VMNetwork").value
                                                $ipAssignment = (Get-UDElement -Id "NICUseDHCP").value
                                                $staticIP = (Get-UDElement -Id "StaticIP").value
                                                $staticGateway = (Get-UDElement -Id "StaticGateway").value
                                                $staticDNS = (Get-UDElement -Id "StaticDNS").value
                                    
                                                if ($selectedNetwork) {
                                                    # Initialize session variable for current VM NICs if it doesn't exist
                                                    if (-not $Session:CurrentVMNICs) { $Session:CurrentVMNICs = @() }
                                        
                                                    $newNIC = [PSCustomObject]@{
                                                        VirtualSwitch = $selectedNetwork
                                                        InterfaceName = "Ethernet$($Session:CurrentVMNICs.Count + 1)"
                                                        UseDhcp       = ($ipAssignment -eq "DHCP")
                                                    }
                                        
                                                    if ($ipAssignment -eq "Static") {
                                                        if (![string]::IsNullOrEmpty($staticIP)) {
                                                            $newNIC | Add-Member -MemberType NoteProperty -Name "IpAddress" -Value $staticIP
                                                        }
                                                        if (![string]::IsNullOrEmpty($staticGateway)) {
                                                            $newNIC | Add-Member -MemberType NoteProperty -Name "Gateway" -Value $staticGateway
                                                        }
                                                        if (![string]::IsNullOrEmpty($staticDNS)) {
                                                            $newNIC | Add-Member -MemberType NoteProperty -Name "DnsServer" -Value $staticDNS
                                                        }
                                                    }
                                        
                                                    $Session:CurrentVMNICs = @($Session:CurrentVMNICs) + $newNIC
                                                    Sync-UDElement -Id "VMNICList"
                                        
                                                    # Clear form
                                                    Set-UDElement -Id "StaticIP" -Properties @{ value = "" }
                                                    Set-UDElement -Id "StaticGateway" -Properties @{ value = "" }
                                                    Set-UDElement -Id "StaticDNS" -Properties @{ value = "" }
                                                }
                                                else {
                                                    Show-UDToast -Message "Please select a virtual switch"
                                                }
                                            } -Icon (New-UDIcon -Icon plus)
                                        } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                        
                                        # Static IP Configuration (conditionally shown)
                                        New-UDGrid -Item -ExtraSmallSize 12 -Id "StaticIPField" -Content {
                                            New-UDCard -Content {
                                                New-UDTypography -Text "Static IP Configuration" -Variant subtitle2 -Style @{ 'margin-bottom' = '12px' }
                                                New-UDGrid -Container -Content {
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                        New-UDTextbox -Id "StaticIP" -Label "IP Address" -Placeholder "e.g., 192.168.1.100" -FullWidth
                                                    } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                        New-UDTextbox -Id "StaticGateway" -Label "Gateway" -Placeholder "e.g., 192.168.1.1" -FullWidth
                                                    } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                        New-UDTextbox -Id "StaticDNS" -Label "DNS Server" -Placeholder "e.g., 8.8.8.8" -FullWidth
                                                    } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                                } -Spacing 2
                                            } -Style @{ 'background-color' = 'rgba(0, 123, 255, 0.05)'; 'border' = '1px solid rgba(0, 123, 255, 0.2)' }
                                        } -Style @{ display = "none"; 'margin-top' = '12px' }
                                        
                                        # Current VM NICs Display
                                        New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                            New-UDDynamic -Id "VMNICList" -Content {
                                                if ($Session:CurrentVMNICs -and $Session:CurrentVMNICs.Count -gt 0) {
                                                    New-UDCard -Content {
                                                        New-UDTypography -Text "Network Adapters for Current VM:" -Variant subtitle2 -Style @{ 'margin-bottom' = '8px' }
                                                        New-UDTable -Data $Session:CurrentVMNICs -Columns @(
                                                            New-UDTableColumn -Property "InterfaceName" -Title "Interface"
                                                            New-UDTableColumn -Property "VirtualSwitch" -Title "Virtual Switch"
                                                            New-UDTableColumn -Property "UseDhcp" -Title "IP Configuration" -Render {
                                                                if ($EventData.UseDhcp) { 
                                                                    "DHCP" 
                                                                }
                                                                else { 
                                                                    $staticConfig = @()
                                                                    if ($EventData.IpAddress) { $staticConfig += "IP: $($EventData.IpAddress)" }
                                                                    if ($EventData.Gateway) { $staticConfig += "GW: $($EventData.Gateway)" }
                                                                    if ($EventData.DnsServer) { $staticConfig += "DNS: $($EventData.DnsServer)" }
                                                                    if ($staticConfig.Count -gt 0) {
                                                                        $staticConfig -join " | "
                                                                    }
                                                                    else {
                                                                        "Static (no config)"
                                                                    }
                                                                }
                                                            }
                                                            New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                                                New-UDButton -Text "Remove" -Size small -Color error -OnClick {
                                                                    $interfaceToRemove = $EventData.InterfaceName
                                                                    $Session:CurrentVMNICs = $Session:CurrentVMNICs | Where-Object { $_.InterfaceName -ne $interfaceToRemove }
                                                                    # Renumber interfaces
                                                                    for ($i = 0; $i -lt $Session:CurrentVMNICs.Count; $i++) {
                                                                        $Session:CurrentVMNICs[$i].InterfaceName = "Ethernet$($i + 1)"
                                                                    }
                                                                    Sync-UDElement -Id "VMNICList"
                                                                } -Icon (New-UDIcon -Icon trash)
                                                            }
                                                        ) -Dense -Size small
                                                    } -Style @{ 'background-color' = 'rgba(0, 123, 255, 0.05)'; 'border' = '1px solid rgba(0, 123, 255, 0.2)' }
                                                }
                                                else {
                                                    New-UDAlert -Severity info -Text "Add network adapters to connect this VM to virtual switches. At least one adapter is required."
                                                }
                                            }
                                        } -Style @{ 'margin-top' = '16px' }
                                    }
                                } -Style @{ 'margin-bottom' = '16px' }
                            }
                            else {
                                New-UDAlert -Severity warning -Text "Please define virtual switches first in the previous step"
                            }
                        }

                        # Add VM Button Card
                        New-UDCard -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDButton -Text "Add Virtual Machine to Lab" -Color primary -Size large -FullWidth -OnClick {
                                        $vmName = (Get-UDElement -Id "VMName").value
                                        $vmSize = (Get-UDElement -Id "VMSize").value
                                        $vmOS = (Get-UDElement -Id "VMOS").value
                            
                                        if ($vmName -and $vmSize -and $vmOS) {
                                            # Check for duplicates
                                            if ($Session:VMs | Where-Object { $_.Name -eq $vmName }) {
                                                Show-UDToast -Message "VM name '$vmName' already exists!"
                                                return
                                            }
                                
                                            # Check if NICs are configured
                                            if (-not $Session:CurrentVMNICs -or $Session:CurrentVMNICs.Count -eq 0) {
                                                Show-UDToast -Message "Please add at least one network adapter to the VM"
                                                return
                                            }
                                
                                            # Get size specifications
                                            $sizeSpecs = switch ($vmSize) {
                                                'Small' { @{ CPU = 2; RAM = 4 } }
                                                'Medium' { @{ CPU = 4; RAM = 8 } }
                                                'Large' { @{ CPU = 8; RAM = 16 } }
                                                'Custom' { 
                                                    $customCPU = (Get-UDElement -Id "CustomCPU").value
                                                    $customRAM = (Get-UDElement -Id "CustomRAM").value
                                                    
                                                    # Validate custom values
                                                    if (-not $customCPU -or -not $customRAM) {
                                                        Show-UDToast -Message "Please specify both CPU cores and RAM for custom VM size"
                                                        return
                                                    }
                                                    
                                                    try {
                                                        $cpuInt = [int]$customCPU
                                                        $ramInt = [int]$customRAM
                                                        
                                                        if ($cpuInt -le 0 -or $ramInt -le 0) {
                                                            Show-UDToast -Message "CPU cores and RAM must be positive numbers"
                                                            return
                                                        }
                                                        
                                                        @{ CPU = $cpuInt; RAM = $ramInt }
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Please enter valid numbers for CPU cores and RAM"
                                                        return
                                                    }
                                                }
                                            }
                                
                                            $newVM = [PSCustomObject]@{
                                                Name            = $vmName
                                                Size            = $vmSize
                                                CPU             = $sizeSpecs.CPU
                                                RAM             = $sizeSpecs.RAM
                                                OS              = $vmOS
                                                NetworkAdapters = $Session:CurrentVMNICs
                                                CustomRoles     = if ($Session:CurrentVMRoles) { $Session:CurrentVMRoles } else { @() }
                                            }
                                
                                            if (-not $Session:VMs) { $Session:VMs = @() }
                                            $Session:VMs = @($Session:VMs) + $newVM
                                            Sync-UDElement -Id "VMList"
                                
                                            # Clear form and NICs
                                            Set-UDElement -Id "VMName" -Properties @{ value = "" }
                                            Set-UDElement -Id "CustomCPU" -Properties @{ value = "" }
                                            Set-UDElement -Id "CustomRAM" -Properties @{ value = "" }
                                            Set-UDElement -Id "CustomVMSpecs" -Properties @{ style = @{ display = "none" } }
                                            $Session:CurrentVMNICs = @()
                                            $Session:CurrentVMRoles = @()
                                            Sync-UDElement -Id "VMNICList"
                                            Sync-UDElement -Id "VMRoleList"
                                        }
                                        else {
                                            Show-UDToast -Message "Please fill in VM Name, Size, and Operating System"
                                        }
                                    } -Icon (New-UDIcon -Icon server)
                                }
                            }
                        }
            
                        New-UDDynamic -Id "VMList" -Content {
                            $vmCount = ($Session:VMs | Measure-Object).Count
                            if ($Session:VMs -and $vmCount -gt 0) {
                                New-UDCard -Title "Defined Virtual Machines ($vmCount)" -Content {
                                    New-UDTable -Data $Session:VMs -Columns @(
                                        New-UDTableColumn -Property "Name" -Title "VM Name"
                                        New-UDTableColumn -Property "Size" -Title "Size"
                                        New-UDTableColumn -Property "CPU" -Title "CPU Cores"
                                        New-UDTableColumn -Property "RAM" -Title "RAM (GB)"
                                        New-UDTableColumn -Property "OS" -Title "Operating System"
                                        New-UDTableColumn -Property "NetworkAdapters" -Title "Network Adapters" -Render {
                                            if ($EventData.NetworkAdapters) {
                                                $adapterCount = ($EventData.NetworkAdapters | Measure-Object).Count
                                                if ($adapterCount -gt 0) {
                                                    $adapters = $EventData.NetworkAdapters | ForEach-Object {
                                                        "$($_.InterfaceName): $($_.VirtualSwitch)"
                                                    }
                                                    $adaptersText = $adapters -join ", "
                                                    New-UDStack -Direction column -Content {
                                                        New-UDTypography -Text "$adapterCount adapter(s)" -Variant caption -Style @{ 'font-weight' = 'bold' }
                                                        New-UDTypography -Text $adaptersText -Variant caption -Style @{ 'font-size' = '0.75rem'; 'opacity' = '0.8' }
                                                    }
                                                }
                                                else {
                                                    New-UDTypography -Text "0 adapters" -Variant caption -Style @{ 'color' = 'red' }
                                                }
                                            }
                                            else {
                                                New-UDTypography -Text "None" -Variant caption -Style @{ 'color' = 'red' }
                                            }
                                        }
                                        New-UDTableColumn -Property "CustomRoles" -Title "Custom Roles" -Render {
                                            if ($EventData.CustomRoles -and $EventData.CustomRoles.Count -gt 0) {
                                                $roleCount = ($EventData.CustomRoles | Measure-Object).Count
                                                $rolesText = $EventData.CustomRoles -join ", "
                                                New-UDStack -Direction column -Content {
                                                    New-UDTypography -Text "$roleCount role(s)" -Variant caption -Style @{ 'font-weight' = 'bold'; 'color' = '#1976d2' }
                                                    New-UDTypography -Text $rolesText -Variant caption -Style @{ 'font-size' = '0.75rem'; 'opacity' = '0.8' }
                                                }
                                            }
                                            else {
                                                New-UDTypography -Text "None" -Variant caption -Style @{ 'opacity' = '0.6' }
                                            }
                                        }
                                        New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                            New-UDButton -Text "Remove" -Size small -OnClick {
                                                $selectedVM = $EventData.Name
                                                $Session:VMs = $Session:VMs | Where-Object { $_.Name -ne $selectedVM }
                                                Sync-UDElement -Id "VMList"
                                            } -Color error -Icon (New-UDIcon -Icon trash)
                                        }
                                    )
                                }
                            }
                            else {
                                New-UDAlert -Severity info -Text "Add virtual machines to your lab. Each VM will be connected to one of your defined virtual switches."
                            }
                        }
                    } -Label "Virtual Machines"
        
                    # Step 4: Finalize Lab
                    New-UDStep -OnLoad {
                        $networkCount = ($Session:Networks | Measure-Object).Count
                        $vmCount = ($Session:VMs | Measure-Object).Count
                        
                        if ($networkCount -gt 0 -and $vmCount -gt 0) {
                            # Lab Summary Card
                            New-UDCard -Title "Lab Configuration Complete" -Content {
                                $labName = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Unnamed Lab" }
                                
                                New-UDGrid -Container -Content {
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                        New-UDCard -Content {
                                            New-UDCardHeader -Title "Lab Information"
                                            New-UDCardBody -Content {
                                                New-UDTypography -Text "Name: $labName" -Variant body1
                                                if (![string]::IsNullOrEmpty($Session:LabDescription)) {
                                                    New-UDTypography -Text "Description: $($Session:LabDescription)" -Variant body2
                                                }
                                                New-UDTypography -Text "Virtual Switches: $networkCount" -Variant body1
                                                New-UDTypography -Text "Virtual Machines: $vmCount" -Variant body1
                                            }
                                        }
                                    }
                        
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                        New-UDCard -Content {
                                            New-UDCardHeader -Title "Resources Summary"
                                            New-UDCardBody -Content {
                                                if ($Session:VMs -and $vmCount -gt 0) {
                                                    $totalCPU = ($Session:VMs | Measure-Object -Property CPU -Sum).Sum
                                                    $totalRAM = ($Session:VMs | Measure-Object -Property RAM -Sum).Sum
                                                    New-UDTypography -Text "Total CPU Cores: $totalCPU" -Variant body1
                                                    New-UDTypography -Text "Total RAM: ${totalRAM}GB" -Variant body1
                                                }
                                            }
                                        }
                                    }
                                }
                            } -Style @{ 'margin-bottom' = '16px' }

                            # Editable Preview Card
                            New-UDCard -Title "Lab Definition Script" -Content {
                                New-UDGrid -Container -Content {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                        New-UDAlert -Severity info -Text "Review and customize your lab definition script below. You can modify the PowerShell code if needed before saving. The script will be saved to the AutomatedLab configuration directory and downloaded for your use."
                                    } -Style @{ 'margin-bottom' = '16px' }
                                    
                                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                        New-UDDynamic -Id "EditableDefinitionPreview" -Content {
                                            $labName = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Lab_$(Get-Date -Format 'yyyyMMdd_HHmmss')" }
                                
                                            $labData = @{
                                                LabName     = $labName
                                                Networks    = $Session:Networks
                                                VMs         = $Session:VMs
                                                Description = $Session:LabDescription
                                            }
                                
                                            try {
                                                $preview = New-AutomatedLabDefinitionScript -LabData $labData
                                                # Store in session for later use
                                                $Session:GeneratedScript = $preview
                                                New-UDCodeEditor -Id "LabDefinitionEditor" -Code $preview -Language "powershell" -Height "500px"
                                            }
                                            catch {
                                                New-UDAlert -Severity error -Text "Error generating definition: $($_.Exception.Message)"
                                            }
                                        }
                                    } -Style @{ 'margin-bottom' = '16px' }
                                    
                                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                New-UDButton -Text "Save Lab" -Color primary -Size large -FullWidth -OnClick {
                                                    $labName = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Lab_$(Get-Date -Format 'yyyyMMdd_HHmmss')" }
                                                    
                                                    # Get the current content from the code editor
                                                    try {
                                                        $editorContent = (Get-UDElement -Id "LabDefinitionEditor").code
                                                        $definitionContent = if ([string]::IsNullOrEmpty($editorContent)) { $Session:GeneratedScript } else { $editorContent }
                                                    }
                                                    catch {
                                                        # Fallback to session stored script if editor content can't be retrieved
                                                        $definitionContent = $Session:GeneratedScript
                                                    }
                                                    
                                                    $fileName = "AutomatedLab_$($labName.Replace(' ', '_'))_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
                                                    
                                                    try {
                                                        # Always save to lab configuration directory
                                                        $configurationParameters = @{
                                                            Name        = $labName
                                                            Scriptblock = [scriptblock]::Create($definitionContent)
                                                        }
                                                        New-LabConfiguration @configurationParameters
                                                        
                                                        # Always download the file
                                                        Start-UDDownload -StringData $definitionContent -FileName $fileName -ContentType "text/plain"
                                                        
                                                        # Show the post-save buttons
                                                        Set-UDElement -Id "PostSaveActions" -Properties @{ style = @{ display = "block" } }
                                                        Set-UDElement -Id "SaveLabButton" -Properties @{ style = @{ display = "none" } }
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Error saving lab: $($_.Exception.Message)" -Duration 5000
                                                    }
                                                } -Icon (New-UDIcon -Icon save)
                                            } -Id "SaveLabButton" -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                            
                                            # Post-save action buttons (hidden initially)
                                            New-UDGrid -Item -ExtraSmallSize 12 -Id "PostSaveActions" -Content {
                                                New-UDGrid -Container -Content {
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                        New-UDButton -Text "Manage Labs" -Color success -Size large -FullWidth -OnClick {
                                                            Invoke-UDRedirect -Url "/Manage-Labs"
                                                        } -Icon (New-UDIcon -Icon cogs)
                                                    } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                        New-UDButton -Text "Start New Lab" -Color secondary -Size large -FullWidth -OnClick {
                                                            $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new()
                                                            
                                                            # Add Default Switch automatically
                                                            $defaultSwitch = @{
                                                                Name            = "Default Switch"
                                                                SwitchType      = "DefaultSwitch"
                                                                Subnet          = "Default Switch NAT"
                                                                IsDefaultSwitch = $true
                                                            }
                                                            $Session:Networks.Add([PSCustomObject]$defaultSwitch)
                                                            
                                                            $Session:VMs = @()
                                                            $Session:CurrentVMNICs = @()
                                                            $Session:LabName = ""
                                                            $Session:LabDescription = ""
                                                            $Session:GeneratedScript = ""
                                                            
                                                            Set-UDElement -Id "LabName" -Properties @{ value = "" }
                                                            Set-UDElement -Id "LabDescription" -Properties @{ value = "" }
                                                            Set-UDElement -Id "SaveLabButton" -Properties @{ style = @{ display = "block" } }
                                                            Set-UDElement -Id "PostSaveActions" -Properties @{ style = @{ display = "none" } }
                                                            Sync-UDElement -Id "NetworkList"
                                                            Sync-UDElement -Id "VMList"
                                                            Sync-UDElement -Id "VMNICList"
                                                            Sync-UDElement -Id "EditableDefinitionPreview"
                                                
                                                            # Reset stepper to first step
                                                            Set-UDElement -Id "LabBuilderStepper" -Properties @{ activeStep = 0 }
                                                        } -Icon (New-UDIcon -Icon plus)
                                                    } -Style @{ 'margin-bottom' = '16px'; 'padding' = '0 8px' }
                                                } -Spacing 2
                                            } -Style @{ display = "none" }
                                        } -Spacing 2
                                    }
                                }
                            }
                        }
                        else {
                            New-UDAlert -Severity warning -Text "Please complete the previous steps to define at least one virtual switch and one virtual machine before finalizing your lab."
                        }
                    } -Label "Finalize Lab"
                }
            }
        }

        # Component to load OS and Network Adapter data when page loads
        New-UDDynamic -Id "DataLoader" -Content {
            if (-not $Session:OSLoaded -or -not $Session:AdaptersLoaded) {
                try {
                    # Load OS data
                    if (-not $Session:OSLoaded) {
                        $availableOS = (Get-LabAvailableOperatingSystem).OperatingSystemName
                        if ($availableOS -and $availableOS.Count -gt 0) {
                            $Session:AvailableOS = $availableOS
                            $Session:OSLoaded = $true
                        }
                        else {
                            # No OS available - don't set OSLoaded to true, will show error message
                            $Session:AvailableOS = @()
                            $Session:OSLoadError = $true
                        }
                    }
                    
                    # Load Network Adapter data
                    if (-not $Session:AdaptersLoaded) {
                        $Session:AvailableNetworkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Disconnected' } | Select-Object Name, InterfaceDescription, Status | Sort-Object Name
                        $Session:AdaptersLoaded = $true
                    }
                    
                    # Only sync MainContent when both are loaded (or OS has error)
                    if (($Session:OSLoaded -or $Session:OSLoadError) -and $Session:AdaptersLoaded) {
                        Sync-UDElement -Id "MainContent"
                        Sync-UDElement -Id "PhysicalAdapterSelect"
                    }
                }
                catch {
                    # Set fallback options if commands fail
                    $Session:AvailableOS = @()
                    $Session:OSLoadError = $true
                    
                    if (-not $Session:AdaptersLoaded) {
                        $Session:AvailableNetworkAdapters = @(
                            @{ Name = "Ethernet"; InterfaceDescription = "Default Ethernet Adapter"; Status = "Up" },
                            @{ Name = "Wi-Fi"; InterfaceDescription = "Default Wi-Fi Adapter"; Status = "Up" }
                        )
                        $Session:AdaptersLoaded = $true
                    }
                    
                    Show-UDToast -Message "Error loading operating systems - please check ISO folder" -Duration 5000
                    Sync-UDElement -Id "MainContent"
                    Sync-UDElement -Id "PhysicalAdapterSelect"
                }
            }
            # Return empty content since this is just for data loading
            New-UDElement -Tag "div" -Content {}
        } -AutoRefresh -AutoRefreshInterval 1000

    }

    # Footer
    New-UDElement -Tag div -Attributes @{ style = @{ 'position' = 'fixed'; 'bottom' = '0'; 'left' = '0'; 'right' = '0'; 'z-index' = '1000' } } -Content {
        New-UDTypography -Text "AutomatedLab UI v1.2.0" -Variant caption -Align center -Style @{
            'padding'          = '8px 16px'
            'opacity'          = '0.7'
            'background-color' = 'rgba(0,0,0,0.05)'
            'border-top'       = '1px solid rgba(0,0,0,0.12)'
        }
    }
}