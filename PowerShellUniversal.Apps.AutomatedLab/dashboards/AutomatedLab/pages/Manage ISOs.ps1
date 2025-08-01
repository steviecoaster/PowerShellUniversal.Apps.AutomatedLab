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
                            
                            New-UDUpload -Id ISOUpload -Text "Select ISO File" -OnUpload {
                                $Data = $Body | ConvertFrom-Json
                                $FileName = $Data.Name
                                $FilePath = $Data.FullName
                            
                                try {
                                    # Add your ISO registration logic here
                                    # Add-LabISOImage -Path $FilePath
                                
                                    Show-UDToast -Message "ISO file '$FileName' uploaded and added successfully!" -MessageColor success
                                    Hide-UDModal
                                
                                    # Refresh the ISO table
                                    Sync-UDElement -Id ISOTable
                                }
                                catch {
                                    Show-UDToast -Message "Failed to add ISO: $($_.Exception.Message)" -MessageColor error
                                }
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
                        $Columns = @(
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
                            New-UDTableColumn -Property IsoPath -Title "ISO Path" -Render {
                                New-UDTypography -Text $EventData.IsoPath -Variant caption -Style @{ 'word-break' = 'break-all'; 'font-family' = 'monospace' }
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
                            New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                New-UDStack -Direction row -Spacing 1 -Content {
                                    New-UDButton -Text "Details" -Color primary -Size small -Variant outlined -OnClick {
                                        $ISODetails = $EventData
                                        Show-UDModal -Content {
                                            New-UDCard -Content {
                                                New-UDTypography -Variant h5 -Text "ISO Details" -Style @{ 'margin-bottom' = '20px'; 'color' = '#9C27B0'; 'text-align' = 'center' }
                                            
                                                # Basic Information
                                                New-UDCard -Content {
                                                    New-UDTypography -Variant h6 -Text "Basic Information" -Style @{ 'margin-bottom' = '12px' }
                                                    New-UDRow -Columns {
                                                        New-UDColumn -SmallSize 6 -Content {
                                                            New-UDTypography -Text "Name:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                            New-UDTypography -Text $ISODetails.OperatingSystemName -Variant body1
                                                        }
                                                        New-UDColumn -SmallSize 6 -Content {
                                                            New-UDTypography -Text "Version:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                            New-UDTypography -Text ($ISODetails.Version -or "N/A") -Variant body1
                                                        }
                                                    }
                                                    New-UDRow -Columns {
                                                        New-UDColumn -SmallSize 12 -Content {
                                                            New-UDTypography -Text "ISO Path:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold'; 'margin-top' = '8px' }
                                                            New-UDTypography -Text $ISODetails.IsoPath -Variant body2 -Style @{ 'font-family' = 'monospace'; 'word-break' = 'break-all' }
                                                        }
                                                    }
                                                } -Style @{ 'background-color' = 'rgba(156, 39, 176, 0.04)'; 'padding' = '12px'; 'margin-bottom' = '16px' }
                                            
                                                # File Information
                                                if (Test-Path $ISODetails.IsoPath) {
                                                    $FileInfo = Get-Item $ISODetails.IsoPath
                                                    New-UDCard -Content {
                                                        New-UDTypography -Variant h6 -Text "File Information" -Style @{ 'margin-bottom' = '12px' }
                                                        New-UDRow -Columns {
                                                            New-UDColumn -SmallSize 6 -Content {
                                                                New-UDTypography -Text "Size:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                                New-UDTypography -Text "$([math]::Round($FileInfo.Length / 1GB, 2)) GB" -Variant body1
                                                            }
                                                            New-UDColumn -SmallSize 6 -Content {
                                                                New-UDTypography -Text "Created:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                                New-UDTypography -Text $FileInfo.CreationTime.ToString("yyyy-MM-dd HH:mm") -Variant body1
                                                            }
                                                        }
                                                    } -Style @{ 'background-color' = 'rgba(76, 175, 80, 0.04)'; 'padding' = '12px' }
                                                }
                                                else {
                                                    New-UDCard -Content {
                                                        New-UDTypography -Variant h6 -Text "File Status" -Style @{ 'margin-bottom' = '8px'; 'color' = '#f44336' }
                                                        New-UDTypography -Text "ISO file not found at the specified path." -Variant body2 -Style @{ 'color' = '#f44336' }
                                                    } -Style @{ 'background-color' = 'rgba(244, 67, 54, 0.04)'; 'padding' = '12px' }
                                                }
                                            } -Style @{ 'max-width' = '600px'; 'margin' = 'auto' }
                                        } -Header {
                                            New-UDTypography -Text "ISO: $($ISODetails.OperatingSystemName)" -Variant h6
                                        } -Footer {
                                            New-UDButton -Text "Close" -Color primary -OnClick {
                                                Hide-UDModal
                                            }
                                        } -FullWidth -MaxWidth 'md'
                                    } -Icon (New-UDIcon -Icon info-circle)
                                
                                    New-UDButton -Text "Remove" -Color error -Size small -Variant outlined -OnClick {
                                        Show-UDModal -Content {
                                            New-UDTypography -Text "Are you sure you want to remove this ISO?" -Variant h6 -Align center
                                            New-UDTypography -Text $EventData.OperatingSystemName -Variant body1 -Align center -Style @{ 'margin' = '16px 0'; 'font-weight' = 'bold' }
                                            New-UDTypography -Text "This action cannot be undone." -Variant body2 -Align center -Style @{ 'color' = '#f44336' }
                                        } -Header {
                                            New-UDTypography -Text "Confirm Removal" -Variant h6
                                        } -Footer {
                                            New-UDButton -Text "Cancel" -OnClick { Hide-UDModal }
                                            New-UDButton -Text "Remove ISO" -Color error -OnClick {
                                                try {
                                                    # Add your ISO removal logic here
                                                    # Remove-LabISOImage -Name $EventData.OperatingSystemName
                                                
                                                    Show-UDToast -Message "ISO '$($EventData.OperatingSystemName)' removed successfully!" -MessageColor success
                                                    Hide-UDModal
                                                    Sync-UDElement -Id ISOTable
                                                }
                                                catch {
                                                    Show-UDToast -Message "Failed to remove ISO: $($_.Exception.Message)" -MessageColor error
                                                }
                                            }
                                        } -MaxWidth 'sm'
                                    } -Icon (New-UDIcon -Icon trash)
                                }
                            }
                        )
                    
                        New-UDCard -Content {
                            New-UDTypography -Variant h6 -Text "Available Operating Systems" -Style @{ 'margin-bottom' = '16px' }
                            New-UDTable -Data $isos -Columns $Columns -Dense -ShowSearch -ShowPagination -PageSize 10 -Sort
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
        New-UDTypography -Text "AutomatedLab UI v1.0.0" -Variant caption -Align center -Style @{
            'padding'          = '8px 16px'
            'opacity'          = '0.7'
            'background-color' = 'rgba(0,0,0,0.05)'
            'border-top'       = '1px solid rgba(0,0,0,0.12)'
        }
    }
}