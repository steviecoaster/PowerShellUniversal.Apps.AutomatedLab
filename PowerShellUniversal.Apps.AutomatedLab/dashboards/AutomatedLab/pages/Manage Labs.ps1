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
                    New-UDTableColumn -Property Actions -Title "Actions" -Render {
                        New-UDStack -Direction row -Spacing 1 -Content {
                            <# Start lab button #>
                            New-UDButton -Text "Start" -Color success -Size small -Variant contained -OnClick {
                            
                                $psuscript = Get-PSUScript -Name 'Start-Lab.ps1' -AppToken $Secret:AU_Token -TrustCertificate
                                Invoke-PSUScript -Script $psuscript -Parameters @{LabName = $($EventData.Lab) } -AppToken $Secret:AU_Token -TrustCertificate
                                Show-UDToast -Message "Starting lab: $($EventData.Lab)" -MessageColor info
                            } -Icon (New-UDIcon -Icon play)
                        
                            <# Stop Lab button #>
                            New-UDButton -Text "Stop" -Color error -Size small -Variant outlined -OnClick {
                                $psuscript = Get-PSUScript -Name 'Stop-Lab.ps1' -AppToken $Secret:AU_Toke -TrustCertificate
                                Invoke-PSUScript -Script $psuscript -Parameters @{LabName = $($EventData.Lab) } -AppToken $Secret:AU_Token -TrustCertificate
                                Show-UDToast -Message "Stopping lab: $($EventData.Lab)" -MessageColor info

                            } -Icon (New-UDIcon -Icon stop)
                        
                            New-UDButton -Text "Details" -Color primary -Size small -Variant text -OnClick {
                                $LabDetails = Get-PSULabConfiguration -Name $EventData.Lab
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
                                    New-UDTypography -Text "Lab Details: $($EventData.Lab)" -Variant h6
                                } -Footer {
                                    New-UDButton -Text "Close" -Color primary -OnClick {
                                        Hide-UDModal
                                    }
                                } -FullWidth -MaxWidth 'md'
                            } -Icon (New-UDIcon -Icon info-circle)
                        }
                    }
                )
            
                New-UDCard -Content {
                    New-UDTypography -Variant h6 -Text "Available Labs" -Style @{ 'margin-bottom' = '16px' }
                    New-UDTable -Data $labs -Columns $Columns -Dense -ShowSearch -ShowPagination -PageSize 10
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