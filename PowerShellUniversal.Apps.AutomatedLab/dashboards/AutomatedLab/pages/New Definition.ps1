$DefinitionPage = New-UDPage -Url '/New-Definition' -Name 'New Definition' -Content {
    
    # Force reset of session variables on page load
    $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new()
    $Session:VMs = @()
    $Session:AvailableOS = @()
    $Session:OSLoaded = $false
    $Session:LabName = ""
    $Session:LabDescription = ""

    New-UDContainer -Content {
        New-UDTypography -Text "AutomatedLab Definition Builder" -Variant h3 -Align center
        New-UDDivider

        # Loading component while fetching OS data
        New-UDDynamic -Id "MainContent" -Content {
            if (-not $Session:OSLoaded) {
                New-UDCard -Content {
                    New-UDStack -Direction column -AlignItems center -Spacing 3 -Content {
                        New-UDProgress -Circular -Color primary -Size medium
                        New-UDTypography -Text "Loading available operating systems..." -Variant h6 -Align center
                        New-UDTypography -Text "Please wait while we fetch the available OS images for your lab." -Variant body2 -Align center -Style @{ 'opacity' = '0.7' }
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
                                
                                            Show-UDToast -Message "Virtual switch '$networkName' added successfully!"
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
                                            New-UDTextbox -Id "PhysicalAdapter" -Label "Physical Adapter Name" -Placeholder "e.g., Ethernet, Wi-Fi"
                                        }
                                    }
                                } -Style @{ display = "none" }
                    
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDButton -Text "Add Default Switch" -Color secondary -OnClick {
                                        if ($Session:Networks | Where-Object { $_.Name -eq "Default Switch" }) {
                                            Show-UDToast -Message "Default Switch already exists!"
                                            return
                                        }
                            
                                        $defaultSwitch = @{
                                            Name            = "Default Switch"
                                            SwitchType      = "DefaultSwitch"
                                            Subnet          = "Default Switch NAT"
                                            IsDefaultSwitch = $true
                                        }
                            
                                        if (-not $Session:Networks) { $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new() }
                                        $Session:Networks.Add([PSCustomObject]$defaultSwitch)
                                        Sync-UDElement -Id "NetworkList"
                                        Show-UDToast -Message "Default Switch added successfully!"
                                    }
                                }
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
                        New-UDCard -Title "Virtual Machine Configuration" -Content {
                            New-UDGrid -Container -Content {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDTextbox -Id "VMName" -Label "VM Name" -Placeholder "e.g., DC01, WEB01, CLIENT01"
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDSelect -Id "VMSize" -Label "VM Size" -Option {
                                        New-UDSelectOption -Name "Small - 2 CPU, 4GB RAM" -Value "Small"
                                        New-UDSelectOption -Name "Medium - 4 CPU, 8GB RAM" -Value "Medium"
                                        New-UDSelectOption -Name "Large - 8 CPU, 16GB RAM" -Value "Large"
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                    New-UDDynamic -Id "OSSelect" -Content {
                                        if ($Session:AvailableOS -and $Session:AvailableOS.Count -gt 0) {
                                            New-UDSelect -Id "VMOS" -Label "Operating System" -Option {
                                                foreach ($os in $Session:AvailableOS) {
                                                    New-UDSelectOption -Name $os -Value $os
                                                }
                                            }
                                        }
                                        else {
                                            # Fallback if no OS data was loaded
                                            New-UDSelect -Id "VMOS" -Label "Operating System" -Option {
                                                New-UDSelectOption -Name "Windows Server 2022 Datacenter" -Value "Windows Server 2022 Datacenter"
                                                New-UDSelectOption -Name "Windows Server 2019 Datacenter" -Value "Windows Server 2019 Datacenter"
                                                New-UDSelectOption -Name "Windows 11 Enterprise" -Value "Windows 11 Enterprise"
                                                New-UDSelectOption -Name "Windows 10 Enterprise" -Value "Windows 10 Enterprise"
                                            }
                                        }
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                    New-UDDynamic -Id "VMNetworkSelect" -Content {
                                        $networkCount = ($Session:Networks | Measure-Object).Count
                                        if ($Session:Networks -and $networkCount -gt 0) {
                                            New-UDCard -Title "Network Interface Cards (NICs)" -Content {
                                                New-UDGrid -Container -Content {
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                                        New-UDSelect -Id "VMNetwork" -Label "Virtual Switch" -Option {
                                                            foreach ($network in $Session:Networks) {
                                                                New-UDSelectOption -Name "$($network.Name) ($($network.Subnet))" -Value $network.Name
                                                            }
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Content {
                                                        New-UDSelect -Id "NICUseDHCP" -Label "IP Assignment" -Option {
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
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Content {
                                                        New-UDButton -Text "Add NIC" -Size small -Color secondary -OnClick {
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
                                                    
                                                                Show-UDToast -Message "Network adapter added to VM configuration"
                                                            }
                                                            else {
                                                                Show-UDToast -Message "Please select a virtual switch"
                                                            }
                                                        } -Icon (New-UDIcon -Icon plus)
                                                    }
                                        
                                                    # Static IP field (conditionally shown)
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Id "StaticIPField" -Content {
                                                        New-UDGrid -Container -Content {
                                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                                New-UDTextbox -Id "StaticIP" -Label "IP Address" -Placeholder "e.g., 192.168.1.100"
                                                            }
                                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                                New-UDTextbox -Id "StaticGateway" -Label "Gateway" -Placeholder "e.g., 192.168.1.1"
                                                            }
                                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Content {
                                                                New-UDTextbox -Id "StaticDNS" -Label "DNS Server" -Placeholder "e.g., 8.8.8.8"
                                                            }
                                                        }
                                                    } -Style @{ display = "none" }
                                                }
                                    
                                                # Show current VM NICs
                                                New-UDDynamic -Id "VMNICList" -Content {
                                                    if ($Session:CurrentVMNICs -and $Session:CurrentVMNICs.Count -gt 0) {
                                                        New-UDCard -Content {
                                                            New-UDTypography -Text "Network Adapters for Current VM:" -Variant subtitle1 -Style @{ 'margin-bottom' = '8px' }
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
                                                                        Show-UDToast -Message "Network adapter removed"
                                                                    } -Icon (New-UDIcon -Icon trash)
                                                                }
                                                            ) -Dense -Size small
                                                        } -Style @{ 'margin-top' = '12px'; 'background-color' = 'rgba(0, 123, 255, 0.05)' }
                                                    }
                                                    else {
                                                        New-UDAlert -Severity info -Text "Add network adapters to connect this VM to virtual switches. At least one adapter is required."
                                                    }
                                                }
                                            }
                                        }
                                        else {
                                            New-UDAlert -Severity warning -Text "Please define virtual switches first in the previous step"
                                        }
                                    }
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                    New-UDButton -Text "Add Virtual Machine" -Color primary -OnClick {
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
                                            }
                                
                                            $newVM = [PSCustomObject]@{
                                                Name            = $vmName
                                                Size            = $vmSize
                                                CPU             = $sizeSpecs.CPU
                                                RAM             = $sizeSpecs.RAM
                                                OS              = $vmOS
                                                NetworkAdapters = $Session:CurrentVMNICs
                                            }
                                
                                            if (-not $Session:VMs) { $Session:VMs = @() }
                                            $Session:VMs = @($Session:VMs) + $newVM
                                            Sync-UDElement -Id "VMList"
                                
                                            # Clear form and NICs
                                            Set-UDElement -Id "VMName" -Properties @{ value = "" }
                                            $Session:CurrentVMNICs = @()
                                            Sync-UDElement -Id "VMNICList"
                                
                                            Show-UDToast -Message "VM '$vmName' added successfully with $($newVM.NetworkAdapters.Count) network adapter(s)!"
                                        }
                                        else {
                                            Show-UDToast -Message "Please fill in VM Name, Size, and Operating System"
                                        }
                                    } -FullWidth
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
                                        New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                            New-UDButton -Text "Remove" -Size small -OnClick {
                                                $selectedVM = $EventData.Name
                                                $Session:VMs = $Session:VMs | Where-Object { $_.Name -ne $selectedVM }
                                                Sync-UDElement -Id "VMList"
                                                Show-UDToast -Message "VM '$selectedVM' removed!"
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
        
                    # Step 4: Review and Generate
                    New-UDStep -OnLoad {
                        New-UDCard -Title "Lab Summary & Generate Definition" -Content {
                            New-UDDynamic -Id "LabSummary" -Content {
                                $labName = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Unnamed Lab" }
                    
                                New-UDGrid -Container -Content {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                        New-UDTypography -Text "Lab Configuration Summary" -Variant h5
                                        New-UDDivider
                                    }
                        
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                        New-UDCard -Content {
                                            New-UDCardHeader -Title "Lab Information"
                                            New-UDCardBody -Content {
                                                New-UDTypography -Text "Name: $labName" -Variant body1
                                                if (![string]::IsNullOrEmpty($Session:LabDescription)) {
                                                    New-UDTypography -Text "Description: $($Session:LabDescription)" -Variant body2
                                                }
                                    
                                                # Use Measure-Object to get accurate counts
                                                $networkCount = ($Session:Networks | Measure-Object).Count
                                                $vmCount = ($Session:VMs | Measure-Object).Count
                                    
                                                New-UDTypography -Text "Virtual Switches: $networkCount" -Variant body1
                                                New-UDTypography -Text "Virtual Machines: $vmCount" -Variant body1
                                            }
                                        }
                                    }
                        
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                        New-UDCard -Content {
                                            New-UDCardHeader -Title "Resources Summary"
                                            New-UDCardBody -Content {
                                                $vmCount = ($Session:VMs | Measure-Object).Count
                                                if ($Session:VMs -and $vmCount -gt 0) {
                                                    $totalCPU = ($Session:VMs | Measure-Object -Property CPU -Sum).Sum
                                                    $totalRAM = ($Session:VMs | Measure-Object -Property RAM -Sum).Sum
                                                    New-UDTypography -Text "Total CPU Cores: $totalCPU" -Variant body1
                                                    New-UDTypography -Text "Total RAM: ${totalRAM}GB" -Variant body1
                                                }
                                                else {
                                                    New-UDTypography -Text "No VMs defined yet" -Variant body2
                                                }
                                            }
                                        }
                                    }
                        
                                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                        New-UDDivider
                                        $networkCount = ($Session:Networks | Measure-Object).Count
                                        $vmCount = ($Session:VMs | Measure-Object).Count
                                        if ($networkCount -gt 0 -and $vmCount -gt 0) {
                                            New-UDGrid -Container -Content {
                                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                                    New-UDCheckBox -Id "SaveLabCheckbox" -Label "Save to lab configuration directory" -LabelPlacement end
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                                    New-UDButton -Text "Generate & Download Lab Definition" -Color primary -OnClick {
                                                        $labData = @{
                                                            LabName     = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Lab_$(Get-Date -Format 'yyyyMMdd_HHmmss')" }
                                                            Networks    = $Session:Networks
                                                            VMs         = $Session:VMs
                                                            Description = $Session:LabDescription
                                                        }
                                            
                                                        $definitionContent = New-AutomatedLabDefinitionScript -LabData $labData
                                                        $fileName = "AutomatedLab_$($labData.LabName.Replace(' ', '_'))_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
                                                        
                                                        # Check if user wants to save to lab configuration directory
                                                        $saveLab = (Get-UDElement -Id "SaveLabCheckbox").checked
                                                        
                                                        if ($saveLab) {
                                                            try {
                                                                $configurationParameters = @{
                                                                    Name        = $Session:LabName
                                                                    Scriptblock = [scriptblock]::Create($definitionContent)
                                                                }
                                                                New-LabConfiguration @configurationParameters
                                                            }
                                                            catch {
                                                                Show-UDToast -Message "Error saving lab definition: $($_.Exception.Message)" -Duration 5000
                                                            }
                                                        }
                                                        
                                                        # Always download the file
                                                        Start-UDDownload -StringData $definitionContent -FileName $fileName -ContentType "text/plain"
                                            
                                                        Show-UDToast -Message "Lab definition '$fileName' generated and downloaded!"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
                                                    New-UDButton -Text "Start New Definition" -Color secondary -OnClick {
                                                        $Session:Networks = [System.Collections.Generic.List[PSCustomObject]]::new()
                                                        $Session:VMs = @()
                                                        $Session:CurrentVMNICs = @()
                                                        $Session:LabName = ""
                                                        $Session:LabDescription = ""
                                                        Set-UDElement -Id "LabName" -Properties @{ value = "" }
                                                        Set-UDElement -Id "LabDescription" -Properties @{ value = "" }
                                                        Sync-UDElement -Id "NetworkList"
                                                        Sync-UDElement -Id "VMList"
                                                        Sync-UDElement -Id "VMNICList"
                                                        Sync-UDElement -Id "LabSummary"
                                                        Show-UDToast -Message "All lab data cleared! Ready to start a new lab."
                                            
                                                        # Reset stepper to first step
                                                        Set-UDElement -Id "LabBuilderStepper" -Properties @{ activeStep = 0 }
                                                    }
                                                }
                                            }
                                        }
                                        else {
                                            New-UDAlert -Severity warning -Text "Please complete the previous steps to define at least one virtual switch and one virtual machine before generating the lab definition."
                                        }
                                    }
                                }
                            }
                        }
            
                        # Preview Definition
                        $networkCount = ($Session:Networks | Measure-Object).Count
                        $vmCount = ($Session:VMs | Measure-Object).Count
                        if ($networkCount -gt 0 -and $vmCount -gt 0) {
                            New-UDCard -Title "Preview Lab Definition" -Content {
                                New-UDDynamic -Id "DefinitionPreview" -Content {
                                    $labName = if (![string]::IsNullOrEmpty($Session:LabName)) { $Session:LabName } else { "Unnamed Lab" }
                        
                                    $labData = @{
                                        LabName     = $labName
                                        Networks    = $Session:Networks
                                        VMs         = $Session:VMs
                                        Description = $Session:LabDescription
                                    }
                        
                                    try {
                                        $preview = New-AutomatedLabDefinitionScript -LabData $labData
                                        New-UDCodeEditor -Code $preview -Language "powershell" -ReadOnly -Height "400px"
                                    }
                                    catch {
                                        New-UDAlert -Severity error -Text "Error generating preview: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    } -Label "Review & Generate"
                }
            }
        }

        # Component to load OS data when page loads
        New-UDDynamic -Id "OSLoader" -Content {
            if (-not $Session:OSLoaded) {
                try {
                    $Session:AvailableOS = (Get-LabAvailableOperatingSystem).OperatingSystemName
                    $Session:OSLoaded = $true
                    Show-UDToast -Message "Available operating systems loaded successfully!" -Duration 2000
                    Sync-UDElement -Id "MainContent"
                }
                catch {
                    # Set fallback OS options if the command fails
                    $Session:AvailableOS = @(
                        "Windows Server 2022 Datacenter",
                        "Windows Server 2019 Datacenter", 
                        "Windows 11 Enterprise",
                        "Windows 10 Enterprise"
                    )
                    $Session:OSLoaded = $true
                    Show-UDToast -Message "Using default operating system options (Get-LabAvailableOperatingSystem failed)" -Duration 3000
                    Sync-UDElement -Id "MainContent"
                }
            }
            # Return empty content since this is just for data loading
            New-UDElement -Tag "div" -Content {}
        } -AutoRefresh -AutoRefreshInterval 1000

    }

    # Footer
    New-UDElement -Tag div -Attributes @{ style = @{ 'position' = 'fixed'; 'bottom' = '0'; 'left' = '0'; 'right' = '0'; 'z-index' = '1000' } } -Content {
        New-UDTypography -Text "AutomatedLab UI v1.1.0" -Variant caption -Align center -Style @{
            'padding'          = '8px 16px'
            'opacity'          = '0.7'
            'background-color' = 'rgba(0,0,0,0.05)'
            'border-top'       = '1px solid rgba(0,0,0,0.12)'
        }
    }
}