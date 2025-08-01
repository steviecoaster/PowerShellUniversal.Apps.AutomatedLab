$NewLabPage = New-UDPage -Url "/New-Lab" -Name "New Lab" -Content {
    New-UDForm -Content {
        New-UDTypography -Variant h4 -Text 'Create Lab Configuration' -Align center -Style @{ 'margin-bottom' = '20px'; 'color' = '#1976d2' }
    
        # Introduction section
        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDCard -Content {
                    New-UDTypography -Variant h6 -Text 'What is a Lab Configuration?' -Style @{ 'margin-bottom' = '10px' }
                    New-UDTypography -Variant body1 -Text 'A lab configuration contains the name of the lab, a definition which defines the vms and associated settings for the lab, and any parameters the definition requires for use.'
                    New-UDTypography -Variant body2 -Text 'Definitions are just PowerShell scripts. This allows you to define very complex labs using all the PowerShell tricks you know and love!' -Style @{ 'margin-top' = '10px'; 'font-style' = 'italic'; 'opacity' = '0.8' }
                } -Style @{ 'margin-bottom' = '20px'; 'border-left' = '4px solid #1976d2'; 'padding' = '16px'; 'background-color' = 'rgba(25, 118, 210, 0.04)' }
            }
        }
    
        New-UDRow -Columns {
            New-UDColumn -SmallSize 6 -Content {
                New-UDTextbox -Id LabName -Label 'Lab Name' -Type text -Variant standard 
            }
            New-UDColumn -SmallSize 6 -Content {
                New-UDTextbox -Id LabDefinition -Label 'Definition Path' -Type text -Variant standard -OnValidate {
                    if (Test-Path ($EventData -replace '"', '')) {
                        New-UDFormValidationResult -Valid
                    }
                    else {
                        New-UDFormValidationResult -ValidationError 'Lab Definition path invalid! Typo?'
                    }
                }
            }
        }

        # Parameters section
        New-UDRow -Columns {
            New-UDColumn -SmallSize 12 -Content {
                New-UDTypography -Variant h6 -Text 'Lab Parameters' -Style @{ 'margin-top' = '20px'; 'margin-bottom' = '10px' }
            
                # Parameter input controls
                New-UDRow -Columns {
                    New-UDColumn -SmallSize 3 -Content {
                        New-UDTextbox -Id ParamKey -Label 'Parameter Name' -Type text -Variant standard
                    }
                    New-UDColumn -SmallSize 3 -Content {
                        New-UDTextbox -Id ParamValue -Label 'Parameter Value' -Type text -Variant standard
                    }
                    New-UDColumn -SmallSize 2 -Content {
                        New-UDButton -Text 'Add Parameter' -Color primary -OnClick {
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
                                }
                                else {
                                    $Parameters += @{ Name = $Key; Value = $Value }
                                }
                            
                                $Session:LabParameters = $Parameters
                            
                                # Clear input fields
                                Set-UDElement -Id ParamKey -Properties @{ value = '' }
                                Set-UDElement -Id ParamValue -Properties @{ value = '' }
                            
                                # Refresh the table
                                Sync-UDElement -Id ParametersTable
                            }
                            else {
                                Show-UDToast -Message 'Please enter both parameter name and value' -MessageColor error
                            }
                        }
                    }
                }
            
                # Dynamic parameters table
                New-UDDynamic -Id ParametersTable -Content {
                    if ($Session:LabParameters -and $Session:LabParameters.Count -gt 0) {
                        New-UDTable -Data $Session:LabParameters -Columns @(
                            New-UDTableColumn -Property Name -Title 'Parameter Name'
                            New-UDTableColumn -Property Value -Title 'Parameter Value'
                            New-UDTableColumn -Property Remove -Title 'Action' -Render {
                                New-UDButton -Text 'Remove' -Size small -Color secondary -OnClick {
                                    $ParamToRemove = $EventData.Name
                                    $Session:LabParameters = $Session:LabParameters | Where-Object { $_.Name -ne $ParamToRemove }
                                    Sync-UDElement -Id ParametersTable
                                    Show-UDToast -Message "Parameter '$ParamToRemove' removed" -MessageColor success
                                }
                            }
                        ) -Dense
                    }
                    else {
                        New-UDTypography -Text 'No parameters added yet' -Variant body2 -Style @{ 'font-style' = 'italic'; 'opacity' = '0.7' }
                    }
                }
            }
        }
    
    
    } -SubmitText 'Create' -OnSubmit {
        # Prepare parameters for submission
        $LabParams = @{}
        if ($Session:LabParameters) {
            foreach ($param in $Session:LabParameters) {
                $LabParams[$param.Name] = $param.Value
            }
        }
    
        New-LabConfiguration -Name $EventData.LabName -Definition $EventData.LabDefinition -Parameters $LabParams
    
        # Clear session parameters after submission
        $Session:LabParameters = @()
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