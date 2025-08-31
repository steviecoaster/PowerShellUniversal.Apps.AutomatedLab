$ManageLabsPage = New-UDPage -Url "/Manage-Labs" -Name "Manage Labs" -Content {
    # Header section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDCard -Content {
                New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                    New-UDIcon -Icon server -Size '2x' -Color primary
                    New-UDStack -Direction column -Content {
                        New-UDTypography -Variant h4 -Text "Lab Management" -Style @{ 'margin-bottom' = '4px' }
                        New-UDTypography -Variant subtitle1 -Text "Start, stop, and monitor your AutomatedLab environments" -Style @{ 'opacity' = '0.8' }
                    }
                }
            } -Style @{ 
                'margin-bottom' = '24px'
                'background'    = 'linear-gradient(135deg, rgba(33, 150, 243, 0.1) 0%, rgba(33, 150, 243, 0.05) 100%)'
                'border-left'   = '4px solid #2196F3'
            }
        }
    }

    # Labs table section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDDynamic -Id "LabsContent" -Content {
                $labs = Get-PSULabConfiguration

                if ($labs -and $labs.Count -gt 0) {
                    $Columns = @(
                        New-UDTableColumn -Property Lab -Title "Lab Name" -Render {
                            New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                New-UDIcon -Icon flask -Size sm -Color success
                                New-UDTypography -Text $EventData.Lab -Variant body1 -Style @{ 'font-weight' = '500' }
                            }
                        }
                        New-UDTableColumn -Property Status -Title "Status" -Render {
                            # You can add actual status logic here
                            New-UDChip -Label "Ready" -Color success -Variant outlined
                        }
                        New-UDTableColumn -Property VMCount -Title "VM Count" -Render {
                            # Get actual VM count for the lab
                            $vmCount = 0
                            try {
                                $labName = $EventData.Lab
                                if (![string]::IsNullOrEmpty($labName)) {
                                    $LabVMs = Get-PSULabInfo -LabName $labName -ErrorAction SilentlyContinue
                                    if ($LabVMs) {
                                        $vmCount = $LabVMs.Count
                                    }
                                }
                            }
                            catch {
                                $vmCount = 0
                            }
                            New-UDChip -Label "$vmCount VMs" -Color info -Variant outlined
                        }
                        New-UDTableColumn -Property Actions -Title "Actions" -Render {
                            New-UDStack -Direction row -Spacing 1 -Content {
                                <# Start lab button #>
                                New-UDButton -Text "Start" -Color success -Size small -Variant contained -OnClick {
                                    $labName = $null
                                
                                    # Try different property names in order
                                    if (![string]::IsNullOrEmpty($EventData.Lab)) {
                                        $labName = $EventData.Lab
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Name)) {
                                        $labName = $EventData.Name
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.LabName)) {
                                        $labName = $EventData.LabName
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Definition)) {
                                        $labName = $EventData.Definition
                                    }
                                
                                    if (![string]::IsNullOrEmpty($labName)) {
                                        try {
                                            $psuscript = Get-PSUScript -Name 'PowerShellUniversal.Apps.AutomatedLab\Start-PSULab' -TrustCertificate
                                            
                                            # Start the job and monitor it in a modal
                                            $Job = Invoke-PSUScript -Script $psuscript -Parameters @{LabName = $labName } -TrustCertificate
                                            
                                            # Show modal with job monitoring
                                            Show-UDModal -Content {
                                                New-UDElement -Id 'ModalJobOutput' -Tag 'pre' -Attributes @{
                                                    style = @{
                                                        'background-color' = '#1e1e1e'
                                                        'color' = '#00ff00'
                                                        'border-radius' = '4px'
                                                        'padding' = '16px'
                                                        'max-height' = '500px'
                                                        'overflow-y' = 'auto'
                                                        'font-family' = 'Consolas, Monaco, monospace'
                                                        'font-size' = '12px'
                                                        'white-space' = 'pre-wrap'
                                                        'min-height' = '300px'
                                                        'width' = '100%'
                                                    }
                                                } -Content {
                                                    "Starting lab: $labName...`r`n"
                                                }
                                            } -Header {
                                                New-UDTypography -Text "Lab Start Progress" -Variant h5
                                            } -FullWidth -MaxWidth 'lg' -Persistent
                                            
                                            # Monitor job in background
                                            while($Job.Status -eq 'Running' -or $Job.Status -eq 'Queued') {
                                                try {
                                                    [array]$Output = Get-PSUJobOutput -Job $Job -TrustCertificate -ErrorAction SilentlyContinue
                                                    
                                                    Set-UDElement -Id 'ModalJobOutput' -Content {
                                                        if ($Output -and $Output.Length -gt 0) {
                                                            ($Output | ForEach-Object { "$_`r`n" }) -join ""
                                                        } else {
                                                            "Waiting for job output..."
                                                        }
                                                    }
                                                } catch {
                                                    Write-Host "Error getting job output: $($_.Exception.Message)"
                                                }
                                                
                                                $Job = Get-PSUJob -Id $Job.Id -TrustCertificate -ErrorAction SilentlyContinue
                                                Start-Sleep -Seconds 2
                                            }
                                            
                                            # Get final output and close modal
                                            try {
                                                [array]$FinalOutput = Get-PSUJobOutput -Job $Job -TrustCertificate -ErrorAction SilentlyContinue
                                                Set-UDElement -Id 'ModalJobOutput' -Content {
                                                    if ($FinalOutput -and $FinalOutput.Length -gt 0) {
                                                        $finalText = ($FinalOutput | ForEach-Object { "$_`r`n" }) -join ""
                                                        "$finalText`r`n`r`n--- Job $($Job.Status) ---"
                                                    } else {
                                                        "Job completed but no output was captured.`r`n`r`n--- Job $($Job.Status) ---"
                                                    }
                                                }
                                            } catch {
                                                Set-UDElement -Id 'ModalJobOutput' -Content {
                                                    "Error retrieving final job output: $($_.Exception.Message)`r`n`r`n--- Job $($Job.Status) ---"
                                                }
                                            }
                                            
                                            Start-Sleep -Seconds 3
                                            Hide-UDModal
                                            Sync-UDElement -Id "LabsContent"
                                        }
                                        catch {
                                            Show-UDToast -Message "Error starting lab: $($_.Exception.Message)" -Duration 7000
                                        }
                                    }
                                    else {
                                        Show-UDToast -Message "Unable to determine lab name"
                                    }
                                } -Icon (New-UDIcon -Icon play)
                        
                                <# Stop Lab button #>
                                New-UDButton -Text "Stop" -Color error -Size small -Variant outlined -OnClick {
                                    $labName = $null
                                
                                    # Try different property names in order
                                    if (![string]::IsNullOrEmpty($EventData.Lab)) {
                                        $labName = $EventData.Lab
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Name)) {
                                        $labName = $EventData.Name
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.LabName)) {
                                        $labName = $EventData.LabName
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Definition)) {
                                        $labName = $EventData.Definition
                                    }
                                
                                    if (![string]::IsNullOrEmpty($labName)) {
                                        try {
                                            $psuscript = Get-PSUScript -Name 'PowerShellUniversal.Apps.AutomatedLab\Stop-PSULab' -TrustCertificate
                                            
                                            # Start the job and monitor it in a modal
                                            $Job = Invoke-PSUScript -Script $psuscript -Parameters @{LabName = $labName } -TrustCertificate
                                            
                                            # Show modal with job monitoring
                                            Show-UDModal -Content {
                                                New-UDElement -Id 'ModalJobOutput' -Tag 'pre' -Attributes @{
                                                    style = @{
                                                        'background-color' = '#1e1e1e'
                                                        'color' = '#ffffff'
                                                        'border-radius' = '4px'
                                                        'padding' = '16px'
                                                        'max-height' = '500px'
                                                        'overflow-y' = 'auto'
                                                        'font-family' = 'Consolas, Monaco, monospace'
                                                        'font-size' = '12px'
                                                        'white-space' = 'pre-wrap'
                                                        'min-height' = '300px'
                                                        'width' = '100%'
                                                    }
                                                } -Content {
                                                    "Stopping lab: $labName...`r`n"
                                                }
                                            } -Header {
                                                New-UDTypography -Text "Lab Stop Progress" -Variant h5
                                            } -FullWidth -MaxWidth 'lg' -Persistent
                                            
                                            # Monitor job in background
                                            while($Job.Status -eq 'Running' -or $Job.Status -eq 'Queued') {
                                                try {
                                                    [array]$Output = Get-PSUJobOutput -Job $Job -TrustCertificate -ErrorAction SilentlyContinue
                                                    
                                                    Set-UDElement -Id 'ModalJobOutput' -Content {
                                                        if ($Output -and $Output.Length -gt 0) {
                                                            ($Output | ForEach-Object { "$_`r`n" }) -join ""
                                                        } else {
                                                            "Waiting for job output..."
                                                        }
                                                    }
                                                } catch {
                                                    Write-Host "Error getting job output: $($_.Exception.Message)"
                                                }
                                                
                                                $Job = Get-PSUJob -Id $Job.Id -TrustCertificate -ErrorAction SilentlyContinue
                                                Start-Sleep -Seconds 2
                                            }
                                            
                                            # Get final output and close modal
                                            try {
                                                [array]$FinalOutput = Get-PSUJobOutput -Job $Job -TrustCertificate -ErrorAction SilentlyContinue
                                                Set-UDElement -Id 'ModalJobOutput' -Content {
                                                    if ($FinalOutput -and $FinalOutput.Length -gt 0) {
                                                        $finalText = ($FinalOutput | ForEach-Object { "$_`r`n" }) -join ""
                                                        "$finalText`r`n`r`n--- Job $($Job.Status) ---"
                                                    } else {
                                                        "Job completed but no output was captured.`r`n`r`n--- Job $($Job.Status) ---"
                                                    }
                                                }
                                            } catch {
                                                Set-UDElement -Id 'ModalJobOutput' -Content {
                                                    "Error retrieving final job output: $($_.Exception.Message)`r`n`r`n--- Job $($Job.Status) ---"
                                                }
                                            }
                                            
                                            Start-Sleep -Seconds 3
                                            Hide-UDModal
                                            Sync-UDElement -Id "LabsContent"
                                        }
                                        catch {
                                            Show-UDToast -Message "Error stopping lab: $($_.Exception.Message)" -Duration 7000
                                        }
                                    }
                                    else {
                                        Show-UDToast -Message "Unable to determine lab name"
                                    }
                                } -Icon (New-UDIcon -Icon stop)
                        
                                New-UDButton -Text "Details" -Color primary -Size small -Variant text -OnClick {
                                    $labName = $null
                                
                                    # Try different property names in order
                                    if (![string]::IsNullOrEmpty($EventData.Lab)) {
                                        $labName = $EventData.Lab
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Name)) {
                                        $labName = $EventData.Name
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.LabName)) {
                                        $labName = $EventData.LabName
                                    }
                                    elseif (![string]::IsNullOrEmpty($EventData.Definition)) {
                                        $labName = $EventData.Definition
                                    }
                                
                                    if (![string]::IsNullOrEmpty($labName)) {
                                        $LabDetails = Get-PSULabConfiguration -Name $labName
                                        Show-UDModal -Content {
                                            New-UDCard -Content {
                                                New-UDTypography -Variant h5 -Text "Lab Configuration Details" -Style @{ 'margin-bottom' = '20px'; 'color' = '#1976d2'; 'text-align' = 'center' }
                                        
                                                # Basic Information Section
                                                New-UDCard -Content {
                                                    New-UDTypography -Variant h6 -Text "Basic Information" -Style @{ 'margin-bottom' = '12px'; 'color' = '#424242' }
                                                    New-UDRow -Columns {
                                                        New-UDColumn -SmallSize 6 -Content {
                                                            New-UDTypography -Text "Lab Name:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                            New-UDTypography -Text $LabDetails.Lab -Variant body1 -Style @{ 'margin-bottom' = '8px' }
                                                        }
                                                        New-UDColumn -SmallSize 6 -Content {
                                                            New-UDTypography -Text "Definition:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                            New-UDTypography -Text $LabDetails.Definition -Variant body1 -Style @{ 'margin-bottom' = '8px'; 'word-break' = 'break-word' }
                                                        }
                                                    }
                                                } -Style @{ 'margin-bottom' = '16px'; 'background-color' = 'rgba(33, 150, 243, 0.04)'; 'padding' = '12px' }
                                        
                                                # Parameters Section
                                                if ($LabDetails.Parameters -and $LabDetails.Parameters.Count -gt 0) {
                                                    New-UDCard -Content {
                                                        New-UDTypography -Variant h6 -Text "Lab Parameters" -Style @{ 'margin-bottom' = '12px'; 'color' = '#424242' }
                                                
                                                        $ParamData = @()
                                                        foreach ($key in $LabDetails.Parameters.Keys) {
                                                            $ParamData += @{
                                                                Name  = $key
                                                                Value = $LabDetails.Parameters[$key]
                                                            }
                                                        }
                                                
                                                        New-UDTable -Data $ParamData -Columns @(
                                                            New-UDTableColumn -Property Name -Title 'Parameter Name' -Render {
                                                                New-UDTypography -Text $EventData.Name -Variant body2 -Style @{ 'font-weight' = '500'; 'color' = '#1976d2' }
                                                            }
                                                            New-UDTableColumn -Property Value -Title 'Parameter Value' -Render {
                                                                New-UDChip -Label $EventData.Value -Color default -Variant outlined
                                                            }
                                                        ) -Dense
                                                    } -Style @{ 'background-color' = 'rgba(76, 175, 80, 0.04)'; 'padding' = '12px' }
                                                }
                                                else {
                                                    New-UDCard -Content {
                                                        New-UDTypography -Variant h6 -Text "Lab Parameters" -Style @{ 'margin-bottom' = '8px'; 'color' = '#424242' }
                                                        New-UDTypography -Text "No parameters configured for this lab." -Variant body2 -Style @{ 'font-style' = 'italic'; 'opacity' = '0.7'; 'text-align' = 'center' }
                                                    } -Style @{ 'background-color' = 'rgba(158, 158, 158, 0.04)'; 'padding' = '12px' }
                                                }
                                            } -Style @{ 'max-width' = '600px'; 'margin' = 'auto' }
                                        } -Header {
                                            New-UDTypography -Text "Lab Details: $labName" -Variant h6
                                        } -Footer {
                                            New-UDButton -Text "Close" -Color primary -OnClick {
                                                Hide-UDModal
                                            }
                                        } -FullWidth -MaxWidth 'md'
                                    }
                                    else {
                                        Show-UDToast -Message "Unable to determine lab name"
                                    }
                                } -Icon (New-UDIcon -Icon info-circle)
                            }
                        }
                    )
            
                    New-UDCard -Content {
                        New-UDTypography -Variant h6 -Text "Available Labs" -Style @{ 'margin-bottom' = '16px' }
                        New-UDTable -Data $labs  -Columns $Columns -Dense -ShowSearch -ShowPagination -PageSize 10 -OnRowExpand {
                            try {
                                $labName = $EventData.Lab
                            
                                if ([string]::IsNullOrEmpty($labName)) {
                                    New-UDCard -Content {
                                        New-UDStack -Direction column -AlignItems center -Spacing 2 -Content {
                                            New-UDIcon -Icon exclamation-triangle -Size lg -Color warning
                                            New-UDTypography -Text "No lab name found" -Variant body2 -Style @{ 'opacity' = '0.7'; 'text-align' = 'center' }
                                            New-UDTypography -Text "Unable to determine lab name from data" -Variant caption -Style @{ 'opacity' = '0.5'; 'text-align' = 'center' }
                                        }
                                    } -Style @{ 'padding' = '20px'; 'text-align' = 'center' }
                                    return
                                }
                            
                                # Use Get-PSULabInfo to get VM data
                                $LabVMs = Get-PSULabInfo -LabName $labName -ErrorAction SilentlyContinue | Select-Object ProcessorCount, Memory, OperatingSystem, MemoryGB, Status, @{N = 'LabVM'; E = { $_.Name } }
                                if ($LabVMs -and $LabVMs.Count -gt 0) {
                                    # Create a table showing individual VM rows
                                    New-UDTable -Data $LabVMs -Columns @(
                                        New-UDTableColumn -Property Name -Title 'VM Name' -Render {
                                            New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                                New-UDIcon -Icon desktop -Size sm -Color primary
                                                New-UDTypography -Text $EventData.LabVM -Variant body2 -Style @{ 'font-weight' = '500' }
                                            }
                                        }
                                        New-UDTableColumn -Property ProcessorCount -Title 'CPUs' -Render {
                                            New-UDChip -Label "$($EventData.ProcessorCount)" -Color success -Variant outlined -Icon (New-UDIcon -Icon microchip)
                                        }
                                        New-UDTableColumn -Property MemoryGB -Title 'Memory (GB)' -Render {
                                            New-UDChip -Label "$($EventData.MemoryGB) GB" -Color info -Variant outlined -Icon (New-UDIcon -Icon memory)
                                        }
                                        New-UDTableColumn -Property Status -Title 'Status' -Render {
                                            $statusColor = switch -Regex ($EventData.Status) {
                                                '^Running$|^Started$|^On$' { 'success' }
                                                '^Stopped$|^Off$|^Shutdown$' { 'error' }
                                                '^Starting$|^Booting$' { 'warning' }
                                                '^Stopping$|^Shutting' { 'warning' }
                                                default { 'info' }
                                            }
                                            $statusIcon = switch -Regex ($EventData.Status) {
                                                '^Running$|^Started$|^On$' { 'power-off' }
                                                '^Stopped$|^Off$|^Shutdown$' { 'power-off' }
                                                '^Starting$|^Booting$' { 'clock' }
                                                '^Stopping$|^Shutting' { 'clock' }
                                                default { 'server' }
                                            }
                                            New-UDChip -Label $EventData.Status -Color $statusColor -Variant default -Icon (New-UDIcon -Icon $statusIcon)
                                        }
                                        New-UDTableColumn -Property OperatingSystem -Title 'Operating System' -Render {
                                            New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                                New-UDIcon -Icon windows -Size sm -Color info
                                                New-UDTypography -Text $EventData.OperatingSystem -Variant body2 -Style @{ 'max-width' = '250px'; 'word-wrap' = 'break-word' }
                                            }
                                        }
                                        New-UDTableColumn -Property Actions -Title 'VM Actions' -Render {
                                            New-UDStack -Direction row -Spacing 1 -Content {
                                                New-UDButton -Text "Start" -Color success -Size small -Variant outlined -OnClick {
                                                    try {
                                                        $psuscript = Get-PSUScript -Name 'PowerShellUniversal.Apps.AutomatedLab\Start-SingleVM' -TrustCertificate
                                                        Invoke-PSUScript -Script $psuscript -Parameters @{LabVM = $EventData.LabVM } -TrustCertificate
                                                        Sync-UDElement -Id "LabsContent"
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Error starting VM: $($_.Exception.Message)" -Duration 5000
                                                    }
                                                } -Icon (New-UDIcon -Icon play)
                                                New-UDButton -Text "Stop" -Color error -Size small -Variant outlined -OnClick {
                                                    try {
                                                        $psuscript = Get-PSUScript -Name 'PowerShellUniversal.Apps.AutomatedLab\Stop-SingleVM' -TrustCertificate
                                                        Invoke-PSUScript -Script $psuscript -Parameters @{LabVM = $EventData.LabVM } -TrustCertificate
                                                        Sync-UDElement -Id "LabsContent"
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Error stopping VM: $($_.Exception.Message)" -Duration 5000
                                                    }
                                                } -Icon (New-UDIcon -Icon stop)
                                            }
                                        }
                                    ) -Dense -ShowSearch -PageSize 10 -Size small -Title "Virtual Machines in $labName"
                                }
                                else {
                                    New-UDCard -Content {
                                        New-UDStack -Direction column -AlignItems center -Spacing 2 -Content {
                                            New-UDIcon -Icon exclamation-triangle -Size lg -Color warning
                                            New-UDTypography -Text "No VMs found in this lab" -Variant body2 -Style @{ 'opacity' = '0.7'; 'text-align' = 'center' }
                                            New-UDTypography -Text "The lab may not be imported or may be empty" -Variant caption -Style @{ 'opacity' = '0.5'; 'text-align' = 'center' }
                                        }
                                    } -Style @{ 'padding' = '20px'; 'text-align' = 'center' }
                                }
                            }
                            catch {
                                New-UDCard -Content {
                                    New-UDStack -Direction column -AlignItems center -Spacing 2 -Content {
                                        New-UDIcon -Icon times-circle -Size lg -Color error
                                        New-UDTypography -Text "Error loading VM information" -Variant body2 -Style @{ 'color' = '#d32f2f'; 'text-align' = 'center' }
                                        New-UDTypography -Text "It looks like this lab hasn't been built yet. Press 'Start' in the Actions menu to build the lab and see metadata." -Variant caption -Style @{ 'opacity' = '0.7'; 'text-align' = 'center'; 'max-width' = '400px'; 'word-wrap' = 'break-word' }
                                    }
                                } -Style @{ 'padding' = '20px'; 'text-align' = 'center' }
                            }
                        }
                    } -Style @{ 'box-shadow' = '0 4px 6px rgba(0, 0, 0, 0.1)' }
                }
                else {
                    # Empty state
                    New-UDCard -Content {
                        New-UDStack -Direction column -Spacing 2 -AlignItems center -Content {
                            New-UDIcon -Icon exclamation-triangle -Size '3x' -Color warning -Style @{ 'opacity' = '0.6' }
                            New-UDTypography -Variant h6 -Text "No Labs Found" -Align center
                            New-UDTypography -Variant body2 -Text "Create your first lab configuration to get started." -Align center -Style @{ 'opacity' = '0.7' }
                            New-UDButton -Text "Create New Lab" -Color primary -Variant contained -OnClick {
                                Invoke-UDRedirect -Url '/New-Lab'
                            } -Icon (New-UDIcon -Icon plus)
                        }
                    } -Style @{ 
                        'text-align' = 'center'
                        'padding'    = '40px'
                        'border'     = '2px dashed rgba(0,0,0,0.12)'
                    }
                }
            } -LoadingComponent {
                New-UDCard -Content {
                    New-UDStack -Direction column -AlignItems center -Spacing 3 -Content {
                        New-UDProgress -Circular -Color primary -Size large
                        New-UDTypography -Text "Loading lab configurations..." -Variant h6 -Align center
                        New-UDTypography -Text "Please wait while we retrieve your lab information." -Variant body2 -Align center -Style @{ 'opacity' = '0.7' }
                    }
                } -Style @{ 'padding' = '60px'; 'text-align' = 'center'; 'min-height' = '300px' }
            }
        }
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