$NewLabPage = New-UDPage -Url "/New-Lab" -Name "New Lab" -Content {
    
    # Header section with gradient background
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDCard -Content {
                New-UDStack -Direction row -Spacing 3 -AlignItems center -Content {
                    New-UDIcon -Icon flask -Size '3x' -Color primary -Style @{ 'opacity' = '0.8' }
                    New-UDStack -Direction column -Content {
                        New-UDTypography -Variant h3 -Text 'Create Lab Configuration' -Style @{ 
                            'margin-bottom' = '8px'
                            'color' = '#1976d2'
                            'font-weight' = '600'
                        }
                        New-UDTypography -Variant subtitle1 -Text 'Build your perfect lab environment with custom configurations' -Style @{ 
                            'opacity' = '0.8'
                            'color' = '#666'
                        }
                    }
                }
            } -Style @{ 
                'margin-bottom' = '16px'
                'background' = 'linear-gradient(135deg, rgba(25, 118, 210, 0.1) 0%, rgba(25, 118, 210, 0.05) 100%)'
                'border-left' = '6px solid #1976d2'
                'padding' = '16px'
                'box-shadow' = '0 4px 12px rgba(0, 0, 0, 0.1)'
            }
        }
    }

    New-UDForm -SubmitText 'Create Lab Configuration' -OnSubmit {
        try {
            # Prepare parameters for submission
            $LabParams = @{}
            if ($Session:LabParameters) {
                foreach ($param in $Session:LabParameters) {
                    $LabParams[$param.Name] = $param.Value
                }
            }

            # Validate required fields
            if ([string]::IsNullOrWhiteSpace($EventData.LabName)) {
                Show-UDToast -Message "❌ Lab Name is required" -MessageColor error -Duration 5000
                return
            }

            if ([string]::IsNullOrWhiteSpace($EventData.Definition)) {
                Show-UDToast -Message "❌ Lab Definition is required" -MessageColor error -Duration 5000
                return
            }

            Show-UDToast -Message "🔄 Creating lab configuration..." -MessageColor info -Duration 3000

            # Prepare parameters for New-LabConfiguration
            $configurationParameters = @{
                Name = $EventData.LabName
                Parameters = $LabParams
            }

            if($EventData.DefinitionType -eq 'File') {
                $DefPath = $EventData.Definition -replace '"',''
                $configurationParameters.Add('Definition',$DefPath)
            }
            else {
                $Url = $EventData.Definition -replace '"',''
                $configurationParameters.Add('Url',$Url)
            }

            New-LabConfiguration @configurationParameters
        
            # Clear session parameters after submission
            $Session:LabParameters = @()
            
            Show-UDToast -Message "✅ Lab configuration '$($EventData.LabName)' created successfully!" -MessageColor success -Duration 5000
        }
        catch {
            Show-UDToast -Message "❌ Error creating lab configuration: $($_.Exception.Message)" -MessageColor error -Duration 7000
        }
    } -Content {
    
        # Introduction section with enhanced styling
        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDCard -Content {
                    New-UDStack -Direction row -Spacing 2 -AlignItems flex-start -Content {
                        New-UDIcon -Icon info-circle -Size lg -Color info -Style @{ 'margin-top' = '4px' }
                        New-UDStack -Direction column -Content {
                            New-UDTypography -Variant h6 -Text 'What is a Lab Configuration?' -Style @{ 
                                'margin-bottom' = '8px'
                                'color' = '#2196F3'
                                'font-weight' = '500'
                            }
                            New-UDTypography -Variant body1 -Text 'A lab configuration contains the name of the lab, a definition which defines the VMs and associated settings for the lab, and any parameters the definition requires for use.' -Style @{
                                'line-height' = '1.6'
                                'margin-bottom' = '6px'
                            }
                            New-UDTypography -Variant body2 -Text '💡 Definitions are just PowerShell scripts. This allows you to define very complex labs using all the PowerShell tricks you know and love!' -Style @{ 
                                'font-style' = 'italic'
                                'opacity' = '0.85'
                                'background-color' = 'rgba(33, 150, 243, 0.1)'
                                'padding' = '6px 10px'
                                'border-radius' = '4px'
                                'border-left' = '3px solid #2196F3'
                            }
                        }
                    }
                } -Style @{ 
                    'margin-bottom' = '16px'
                    'border' = '1px solid rgba(33, 150, 243, 0.2)'
                    'padding' = '12px'
                    'background-color' = 'rgba(33, 150, 243, 0.02)'
                    'border-radius' = '8px'
                }
            }
        }
    
        # Lab Configuration Section with enhanced styling
        New-UDCard -Content {
            New-UDTypography -Variant h5 -Text '🔧 Lab Configuration' -Style @{ 
                'margin-bottom' = '12px'
                'color' = '#424242'
                'font-weight' = '500'
            }
            
            New-UDRow -Columns {
                New-UDColumn -SmallSize 6 -Content {
                    New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                        New-UDIcon -Icon tag -Color primary
                        New-UDTextbox -Id LabName -Label 'Lab Name' -Type text -Variant outlined
                    }
                }
                New-UDColumn -SmallSize 6 -Content {
                    New-UDStack -Direction column -Content {
                        New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                            New-UDIcon -Icon cogs -Color secondary
                            New-UDTypography -Text 'Lab Definition Source' -Variant h6 -Style @{ 
                                'color' = '#424242'
                                'font-weight' = '500'
                            }
                        }
                        New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                            New-UDSelect -Id "DefinitionType" -Option {
                                New-UDSelectOption -Name '📁 File' -Value 'File'
                                New-UDSelectOption -Name '🌐 URL' -Value 'Url'
                            } -DefaultValue 'File'
                            New-UDTextbox -Id 'Definition' -Placeholder 'Enter definition location...' -Variant outlined
                        }
                    }
                }
            }
        } -Style @{ 
            'margin-bottom' = '16px'
            'padding' = '16px'
            'border-radius' = '8px'
            'box-shadow' = '0 2px 8px rgba(0, 0, 0, 0.1)'
        }

        # Parameters section with enhanced styling
        New-UDCard -Content {
            New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                New-UDIcon -Icon sliders-h -Size lg -Color secondary
                New-UDTypography -Variant h5 -Text 'Lab Parameters' -Style @{ 
                    'color' = '#424242'
                    'font-weight' = '500'
                }
            }
            
            New-UDTypography -Variant body2 -Text 'Add custom parameters that your lab definition script can use' -Style @{ 
                'margin-bottom' = '12px'
                'opacity' = '0.8'
                'font-style' = 'italic'
            }
            
            # Parameter input controls with better styling
            New-UDCard -Content {
                New-UDRow -Columns {
                    New-UDColumn -SmallSize 4 -Content {
                        New-UDTextbox -Id ParamKey -Placeholder 'Parameter Name' -Type text -Variant outlined
                    }
                    New-UDColumn -SmallSize 4 -Content {
                        New-UDTextbox -Id ParamValue -Placeholder 'Parameter Value' -Type text -Variant outlined
                    }
                    New-UDColumn -SmallSize 4 -Content {
                        New-UDButton -Text 'Add Parameter' -Color primary -Variant contained -Icon (New-UDIcon -Icon plus) -OnClick {
                            $Key = (Get-UDElement -Id ParamKey).value
                            $Value = (Get-UDElement -Id ParamValue).value
                        
                            if ($Key -and $Value) {
                                # Get existing parameters from session
                                $Parameters = $Session:LabParameters
                                if (-not $Parameters) { $Parameters = @() }
                            
                                # Add new parameter (avoid duplicates)
                                $ExistingParam = $Parameters | Where-Object { $_.Name -eq $Key }
                                if ($ExistingParam) {
                                    $ExistingParam.Value = $Value
                                    Show-UDToast -Message "Parameter '$Key' updated!" -MessageColor success -Duration 3000
                                }
                                else {
                                    $Parameters += @{ Name = $Key; Value = $Value }
                                    Show-UDToast -Message "Parameter '$Key' added!" -MessageColor success -Duration 3000
                                }
                            
                                $Session:LabParameters = $Parameters
                            
                                # Clear input fields
                                Set-UDElement -Id ParamKey -Properties @{ value = '' }
                                Set-UDElement -Id ParamValue -Properties @{ value = '' }
                            
                                # Refresh the table
                                Sync-UDElement -Id ParametersTable
                            }
                            else {
                                Show-UDToast -Message 'Please enter both parameter name and value' -MessageColor error -Duration 4000
                            }
                        }
                    }
                }
            } -Style @{ 
                'background-color' = 'rgba(63, 81, 181, 0.04)'
                'border' = '1px dashed rgba(63, 81, 181, 0.3)'
                'margin-bottom' = '12px'
                'padding' = '12px'
            }
            
            # Enhanced parameters table
            New-UDDynamic -Id ParametersTable -Content {
                if ($Session:LabParameters -and $Session:LabParameters.Count -gt 0) {
                    New-UDCard -Content {
                        New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                            New-UDIcon -Icon list -Color success
                            New-UDTypography -Text "Active Parameters ($(($Session:LabParameters).Count))" -Variant subtitle1 -Style @{ 
                                'font-weight' = '500'
                                'color' = '#388e3c'
                            }
                        }
                        New-UDTable -Data $Session:LabParameters -Columns @(
                            New-UDTableColumn -Property Name -Title 'Parameter Name' -Render {
                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                    New-UDIcon -Icon key -Size sm -Color primary
                                    New-UDTypography -Text $EventData.Name -Variant body2 -Style @{ 'font-weight' = '500' }
                                }
                            }
                            New-UDTableColumn -Property Value -Title 'Parameter Value' -Render {
                                New-UDChip -Label $EventData.Value -Color default -Variant outlined
                            }
                            New-UDTableColumn -Property Remove -Title 'Actions' -Render {
                                New-UDButton -Text 'Remove' -Size small -Color error -Variant outlined -Icon (New-UDIcon -Icon trash) -OnClick {
                                    $ParamToRemove = $EventData.Name
                                    $Session:LabParameters = $Session:LabParameters | Where-Object { $_.Name -ne $ParamToRemove }
                                    Sync-UDElement -Id ParametersTable
                                    Show-UDToast -Message "Parameter '$ParamToRemove' removed" -MessageColor warning -Duration 3000
                                }
                            }
                        ) -Dense -Sort -ShowSearch
                    } -Style @{ 
                        'background-color' = 'rgba(76, 175, 80, 0.04)'
                        'border-left' = '4px solid #4caf50'
                    }
                }
                else {
                    New-UDCard -Content {
                        New-UDStack -Direction column -Spacing 2 -AlignItems center -Content {
                            New-UDIcon -Icon inbox -Size '2x' -Color disabled -Style @{ 'opacity' = '0.5' }
                            New-UDTypography -Text 'No parameters added yet' -Variant h6 -Align center -Style @{ 'color' = '#9e9e9e' }
                            New-UDTypography -Text 'Add parameters above to customize your lab configuration' -Variant body2 -Align center -Style @{ 
                                'opacity' = '0.7'
                                'font-style' = 'italic'
                            }
                        }
                    } -Style @{ 
                        'border' = '2px dashed rgba(0,0,0,0.12)'
                        'background-color' = 'rgba(245, 245, 245, 0.5)'
                        'padding' = '20px'
                        'text-align' = 'center'
                    }
                }
            }
        } -Style @{ 
            'margin-bottom' = '20px'
            'padding' = '16px'
            'border-radius' = '8px'
            'box-shadow' = '0 2px 8px rgba(0, 0, 0, 0.1)'
        }

    }

    # Add spacing below the form
    New-UDElement -Tag "div" -Attributes @{ style = @{ 'margin-bottom' = '350px' } }

}