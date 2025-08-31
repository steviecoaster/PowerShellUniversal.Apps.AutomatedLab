$ManageISOsPage = New-UDPage -Url "/Manage-ISOs" -Name "Manage ISOs" -Content {
    # Header section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDCard -Content {
                New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                    New-UDIcon -Icon compact-disc -Size '2x' -Color primary
                    New-UDStack -Direction column -Content {
                        New-UDTypography -Variant h4 -Text "ISO Management" -Style @{ 'margin-bottom' = '4px' }
                        New-UDTypography -Variant subtitle1 -Text "Add/Remove available ISOs for your AutomatedLab environment" -Style @{ 'opacity' = '0.8' }
                    }
                }
            } -Style @{ 
                'margin-bottom' = '24px'
                'background'    = 'linear-gradient(135deg, rgba(156, 39, 176, 0.1) 0%, rgba(156, 39, 176, 0.05) 100%)'
                'border-left'   = '4px solid #9C27B0'
            }
        }
    }

    # Add ISO Button Row
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDCard -Content {
                New-UDButton -Text "Add New ISO" -Color success -Variant contained -Size large -Icon (New-UDIcon -Icon plus-circle) -OnClick {
                    Show-UDModal -Content {
                        New-UDCard -Content {
                            New-UDTypography -Variant h6 -Text "ISO File Upload" -Style @{ 'margin-bottom' = '16px'; 'text-align' = 'center' }
                            New-UDForm -Content {
                                New-UDTextbox -Id 'ISOUploadFile' -Label ISO -Placeholder 'Enter path to ISO' -OnValidate {
                                    if(Test-Path $EventData.Replace('"','')) {
                                        New-UDValidationResult -Valid
                                    }
                                    else {
                                        New-UDValidationResult -ValidationError 'ISO file does not exist. Please correct the path and try again.'
                                    }
                                }
                            }  -OnSubmit {
                                New-AutomatedLabISO -ISOFile $($EventData.ISOUploadFile -replace '"','')
                                Sync-UDElement -Id ISOTable
                                Hide-UDModal
                            }
                            
                            New-UDTypography -Variant caption -Text "Supported formats: .iso files only" -Style @{ 'opacity' = '0.7'; 'margin-top' = '16px'; 'text-align' = 'center' }
                        } -Style @{ 'max-width' = '400px'; 'margin' = 'auto'; 'padding' = '24px' }
                    } -Header {
                        New-UDTypography -Text "Add New ISO" -Variant h6
                    } -Footer {
                        New-UDButton -Text "Cancel" -OnClick {
                            Hide-UDModal
                        }
                    } -FullWidth -MaxWidth 'sm'
                }
            } -Style @{ 'text-align' = 'center'; 'margin-bottom' = '24px'; 'padding' = '16px' }
        }
    }

    # ISOs table section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDDynamic -Id ISOTable -Content {
                try {
                    $isos = Get-LabAvailableOperatingSystem -ErrorAction SilentlyContinue
                
                    if ($isos -and $isos.Count -gt 0) {
                        # Group ISOs by OS Family
                        $groupedIsos = $isos | Group-Object { 
                            # Extract OS Family from OperatingSystemName
                            $osName = $_.OperatingSystemName
                            switch -Regex ($osName) {
                                'Windows 10' { 'Windows 10' }
                                'Windows 11' { 'Windows 11' }
                                'Windows Server 2025' { 'Windows Server 2025' }
                                'Windows Server 2022' { 'Windows Server 2022' }
                                'Windows Server 2019' { 'Windows Server 2019' }
                                'Windows Server 2016' { 'Windows Server 2016' }
                                'Windows Server 2012' { 'Windows Server 2012' }
                                'Windows 8' { 'Windows 8' }
                                'Windows 7' { 'Windows 7' }
                                'Ubuntu' { 'Ubuntu' }
                                'CentOS' { 'CentOS' }
                                'RHEL|Red Hat' { 'Red Hat Enterprise Linux' }
                                default { 'Other' }
                            }
                        }

                        # Define columns for the expandable table
                        $Columns = @(
                            New-UDTableColumn -Property Name -Title "OS Family" -Render {
                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                    New-UDIcon -Icon windows -Size sm -Color primary
                                    New-UDTypography -Text $EventData.Name -Variant body1 -Style @{ 'font-weight' = '600' }
                                }
                            }
                            New-UDTableColumn -Property Count -Title "Available Editions" -Render {
                                $count = if ($null -eq $EventData.Count) { 0 } else { $EventData.Count }
                                New-UDChip -Label "$count Editions" -Color success -Variant outlined
                            }
                            New-UDTableColumn -Property IsoPath -Title "ISO Path" -Render {
                                New-UDTypography -Text $EventData.Group[0].IsoPath -Variant caption -Style @{ 'word-break' = 'break-all'; 'font-family' = 'monospace' }
                            }
                            New-UDTableColumn -Property TotalSize -Title "Total Size" -Render {
                                if (Test-Path $EventData.Group[0].IsoPath) {
                                    $sizeGB = [math]::Round((Get-Item $EventData.Group[0].IsoPath -ErrorAction SilentlyContinue).Length / 1GB, 2)
                                    New-UDTypography -Text "$sizeGB GB" -Variant body2
                                }
                                else {
                                    New-UDTypography -Text "N/A" -Variant body2 -Style @{ 'opacity' = '0.6' }
                                }
                            }
                            New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                New-UDStack -Direction row -Spacing 1 -Content {
                                    New-UDButton -Text "Remove ISO" -Color error -Size small -Variant outlined -OnClick {
                                        Show-UDModal -Content {
                                            New-UDTypography -Text "Are you sure you want to remove ALL ISOs from this family?" -Variant h6 -Align center
                                            New-UDTypography -Text $EventData.Name -Variant body1 -Align center -Style @{ 'margin' = '16px 0'; 'font-weight' = 'bold' }
                                            New-UDTypography -Text "This will remove the following Operating Systems:" -Variant body2 -Align center -Style @{ 'margin-bottom' = '8px' }
                                            foreach ($iso in $EventData.Group) {
                                                New-UDTypography -Text "• $($iso.OperatingSystemName)" -Variant body2 -Align center -Style @{ 'font-family' = 'monospace'; 'margin' = '4px 0' }
                                            }
                                            New-UDTypography -Text "This action cannot be undone." -Variant body2 -Align center -Style @{ 'color' = '#f44336'; 'margin-top' = '16px' }
                                        } -Header {
                                            New-UDTypography -Text "Confirm Family Removal" -Variant h6
                                        } -Footer {
                                            New-UDButton -Text "Cancel" -OnClick { Hide-UDModal }
                                            New-UDButton -Text "Remove All ISOs" -Color error -OnClick {
                                                try {
                                                    Remove-Item $EventData.Group[0].IsoPath -Force
                                                    Show-UDToast -Message "Removed ISO(s) for family '$($EventData.Name)' successfully!"
                                                    Hide-UDModal
                                                    Sync-UDElement -Id ISOTable
                                                }
                                                catch {
                                                    Show-UDToast -Message "Failed to remove ISOs: $($_.Exception.Message)"
                                                }
                                            }
                                        } -MaxWidth 'md'
                                    } -Icon (New-UDIcon -Icon trash)
                                }
                            }
                        )

                        New-UDCard -Content {
                            New-UDTypography -Variant h6 -Text "Available Operating Systems by Family" -Style @{ 'margin-bottom' = '16px' }
                            New-UDTable -Data $groupedIsos -Columns $Columns -Dense -ShowSearch -ShowPagination -PageSize 10 -Sort -OnRowExpand {
                                try {
                                    $familyName = $EventData.Name
                                    $familyIsos = $EventData.Group
                                    
                                    if ([string]::IsNullOrEmpty($familyName) -or !$familyIsos) {
                                        New-UDCard -Content {
                                            New-UDStack -Direction column -AlignItems center -Spacing 2 -Content {
                                                New-UDIcon -Icon exclamation-triangle -Size lg -Color warning
                                                New-UDTypography -Text "No ISOs found for this family" -Variant body2 -Style @{ 'opacity' = '0.7'; 'text-align' = 'center' }
                                            }
                                        } -Style @{ 'padding' = '20px'; 'text-align' = 'center' }
                                        return
                                    }
                                    
                                    # Return the expanded table for individual ISOs in this family
                                    New-UDTable -Data $familyIsos -Columns @(
                                        New-UDTableColumn -Property OperatingSystemName -Title "Operating System" -Render {
                                            New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                                New-UDIcon -Icon compact-disc -Size sm -Color primary
                                                New-UDTypography -Text $EventData.OperatingSystemName -Variant body1 -Style @{ 'font-weight' = '500' }
                                            }
                                        }
                                        New-UDTableColumn -Property Version -Title "Version" -Render {
                                            if ($EventData.Version) {
                                                New-UDChip -Label $EventData.Version -Color default -Variant outlined
                                            }
                                            else {
                                                New-UDTypography -Text "N/A" -Variant body2 -Style @{ 'opacity' = '0.6' }
                                            }
                                        }
                                        New-UDTableColumn -Property Size -Title "Size" -Render {
                                            if (Test-Path $EventData.IsoPath) {
                                                $SizeGB = [math]::Round((Get-Item $EventData.IsoPath).Length / 1GB, 2)
                                                New-UDTypography -Text "$SizeGB GB" -Variant body2
                                            }
                                            else {
                                                New-UDChip -Label "Missing" -Color error -Variant filled -Size small
                                            }
                                        }
                                    ) -Dense
                                }
                                catch {
                                    New-UDCard -Content {
                                        New-UDStack -Direction column -AlignItems center -Spacing 2 -Content {
                                            New-UDIcon -Icon exclamation-triangle -Size lg -Color error
                                            New-UDTypography -Text "Error loading ISOs for this family" -Variant body2 -Style @{ 'opacity' = '0.7'; 'text-align' = 'center' }
                                            New-UDTypography -Text $_.Exception.Message -Variant caption -Style @{ 'opacity' = '0.5'; 'text-align' = 'center' }
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
                                New-UDIcon -Icon compact-disc -Size '3x' -Color disabled -Style @{ 'opacity' = '0.5' }
                                New-UDTypography -Variant h6 -Text "No ISOs Found" -Align center
                                New-UDTypography -Variant body2 -Text "Add your first ISO to get started." -Align center -Style @{ 'opacity' = '0.7' }
                                New-UDButton -Text "Add New ISO" -Color success -Variant contained -OnClick {
                                    # Trigger the same upload modal
                                    Invoke-UDJavaScript -JavaScript "document.querySelector('[data-testid=\"add-iso-button\"]').click();"
                                } -Icon (New-UDIcon -Icon plus)
                            }
                        } -Style @{ 
                            'text-align' = 'center'
                            'padding'    = '40px'
                            'border'     = '2px dashed rgba(0,0,0,0.12)'
                        }
                    }
                }
                catch {
                    New-UDCard -Content {
                        New-UDTypography -Variant h6 -Text "Error Loading ISOs" -Style @{ 'color' = '#f44336'; 'margin-bottom' = '8px' }
                        New-UDTypography -Text "Failed to retrieve operating systems: $($_.Exception.Message)" -Variant body2 -Style @{ 'color' = '#f44336' }
                    } -Style @{ 'background-color' = 'rgba(244, 67, 54, 0.04)'; 'padding' = '16px' }
                }
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