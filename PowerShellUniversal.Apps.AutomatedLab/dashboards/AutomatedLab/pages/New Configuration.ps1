$NewLabPage = New-UDPage -Url "/New-Configuration" -Name "New Lab Configuration" -Content {
    $Session:LabParameters = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    New-UDCard -Content {

        New-UDStack -Direction row -Spacing 2 -AlignItems flex-start -Content {
            New-UDIcon -Icon info-circle -Size lg -Color info -Style @{ 'margin-top' = '4px' }
            New-UDStack -Direction column -Content {
                New-UDTypography -Variant h6 -Text 'What is a Lab Configuration?' -Style @{ 
                    'margin-bottom' = '8px'
                    'color'         = '#2196F3'
                    'font-weight'   = '500'
                }
                New-UDTypography -Variant body1 -Text 'A lab configuration contains the name of the lab, a definition (the PowerShell script containing the logic to build a lab), and any parameters the definition requires for use.' -Style @{
                    'line-height'   = '1.6'
                    'margin-bottom' = '6px'
                }
                New-UDTypography -Variant body2 -Text '💡 Definitions are just PowerShell scripts. This allows you to define very complex labs using all the PowerShell tricks you know and love!' -Style @{ 
                    'font-style'       = 'italic'
                    'opacity'          = '0.85'
                    'background-color' = 'rgba(33, 150, 243, 0.1)'
                    'padding'          = '6px 10px'
                    'border-radius'    = '4px'
                    'border-left'      = '3px solid #2196F3'
                }
            }
        }
    } -Style @{ 
        'margin-bottom'    = '16px'
        'border'           = '1px solid rgba(33, 150, 243, 0.2)'
        'padding'          = '12px'
        'background-color' = 'rgba(33, 150, 243, 0.02)'
        'border-radius'    = '8px'
    }

    New-UDCard -Content {
        New-UDTypography -Variant h5 -Text '🔧 Add a Configuration' -Style @{
            'margin-bottom' = '1px'
            'color'         = '#424242'
            'font-weight'   = '500'
        }

        New-UDForm -SubmitText 'Create Configuration' -ButtonVariant contained -OnSubmit {
            try {
                # Prepare parameters for submission
                $LabParams = @{}
                if ($Session:LabParameters) {
                    foreach ($param in $Session:LabParameters) {
                        $LabParams[$param.ParameterName] = $param.ParameterValue
                    }
                }

                # Validate required fields
                if ([string]::IsNullOrWhiteSpace($EventData.LabName)) {
                    Show-UDToast -Message "❌ Lab Name is required" -Duration 5000
                    return
                }

                if ([string]::IsNullOrWhiteSpace($EventData.Definition)) {
                    Show-UDToast -Message "❌ Lab Definition is required" -Duration 5000
                    return
                }

                Show-UDToast -Message "🔄 Creating lab configuration..." -Duration 3000

                # Call New-LabConfiguration - avoid parameter name conflicts completely
                if ($EventData.DefinitionType -eq 'File') {
                    $DefPath = $EventData.Definition -replace '"', ''
                    New-LabConfiguration -Name $EventData.LabName -Definition $DefPath -Parameters $LabParams
                }
                else {
                    $Url = $EventData.Definition -replace '"', ''
                    New-LabConfiguration -Name $EventData.LabName -Url $Url -Parameters $LabParams
                }
        
                # Clear session parameters after submission - maintain generic collection type
                $Session:LabParameters.Clear()
            
                Show-UDToast -Message "✅ Lab configuration '$($EventData.LabName)' created successfully!" -Duration 5000
            }
            catch {
                Show-UDToast -Message "❌ Error creating lab configuration: $($_.Exception.Message)" -Duration 7000
            }
        } -Content {
            New-UDTypography -Variant h6 -Text 'Lab Name' -Style @{
                'margin-bottom' = '8px'
                'color'         = '#424242'
                'font-weight'   = '500'
            }
            New-UDTextbox -Id 'LabName' -Placeholder 'Enter a unique name for this lab configuration...' -FullWidth -Style @{
                'margin-bottom' = '16px'
            }

            New-UDTypography -Variant h6 -Text 'Lab Defintion (.ps1 file)' -Style @{
                'margin-bottom' = '12px'
                'color'         = '#424242'
                'font-weight'   = '500'
            }
            New-UDRow -Columns {
                New-UDColumn -SmallSize 6 -Content {
                    New-UDSelect -Id "DefinitionType" -Option {
                        New-UDSelectOption -Name '📁 File' -Value 'File'
                        New-UDSelectOption -Name '🌐 URL' -Value 'Url'
                    } -DefaultValue 'File'
                }

                New-UDColumn -SmallSize 6 -Content {
                    New-UDTextbox -Id 'Definition' -Placeholder 'Enter definition location...'
                }
            }

            # Parameters Section - Side by Side with Stack
            New-UDStack -Direction row -Spacing 2 -Content {
                # Parameter Input Card (Left Side)
                New-UDCard -Content {
                    New-UDTypography -Variant h6 -Text '➕ Add Parameters' -Style @{
                        'margin-bottom' = '8px'
                        'color'         = '#424242'
                        'font-weight'   = '500'
                    }
                    New-UDAlert -Severity info -Text 'Since definitions are PowerShell scripts, you can save parameters (and their values) to pass to the definition when it runs. For example, a lab definition might use a "DomainName" parameter to build labs with different domain names from the same definition.' -Style @{
                        'margin-bottom' = '12px'
                        'font-size'     = '0.875rem'
                    }
                    New-UDRow -Columns {
                        New-UDColumn -Size 6 -Content {
                            New-UDTextbox -Id ParamKey -Placeholder 'Parameter Name' -Type text
                        }
                        New-UDColumn -Size 6 -Content {
                            New-UDTextbox -Id ParamValue -Placeholder 'Parameter Value' -Type text
                        }
                    }
                    New-UDRow -Columns {
                        New-UDColumn -Size 12 -Content {
                            New-UDButton -Text 'Add Parameter' -Color primary -Icon (New-UDIcon -Icon plus) -FullWidth -OnClick {
                                $Key = (Get-UDElement -Id ParamKey).value
                                $Value = (Get-UDElement -Id ParamValue).value
                            
                                if ($Key -and $Value) {

                                    $parameterToAdd = [PSCustomObject]@{
                                        ParameterName  = $Key
                                        ParameterValue = $Value
                                    }

                                    $ExistParam = $Session:LabParameters | Where-Object { $_.ParameterName -eq $Key }
                                    if ($ExistParam) {
                                        $ExistParam.ParameterValue = $Value
                                        Show-UDToast -Message "Parameter '$Key' updated!" -Duration 3000
                                    }
                                    else {
                                        $Session:LabParameters.Add($parameterToAdd)
                                        Show-UDToast -Message "Parameter '$Key' added!" -Duration 3000
                                    }
                            
                                    # Clear input fields
                                    Set-UDElement -Id ParamKey -Properties @{ value = '' }
                                    Set-UDElement -Id ParamValue -Properties @{ value = '' }
                            
                                    # Refresh the table
                                    Sync-UDElement -Id ParametersTable
                                }
                                else {
                                    Show-UDToast -Message 'Please enter both parameter name and value' -Duration 4000
                                }
                            } -Style @{ 'margin-top' = '12px' }
                        }
                    }
                } -Style @{
                    'flex'             = '1'
                    'margin-right'     = '8px'
                    'background-color' = 'rgba(63, 81, 181, 0.04)'
                    'border'           = '1px dashed rgba(63, 81, 181, 0.3)'
                }

                # Parameters Table (Right Side)
                New-UDCard -Content {
                    New-UDTypography -Variant h6 -Text '📋 Current Parameters' -Style @{
                        'margin-bottom' = '12px'
                        'color'         = '#424242'
                        'font-weight'   = '500'
                    }
                    New-UDDynamic -Id 'ParametersTable' -Content {
                        $Parameters = $Session:LabParameters
                        if ($Parameters -and $Parameters.Count -gt 0) {
                            New-UDTable -Data $Parameters -Columns @(
                                New-UDTableColumn -Property ParameterName -Title 'Parameter Name' -Render {
                                    New-UDTypography -Text $EventData.ParameterName -Variant body2 -Style @{ 'font-weight' = '500' }
                                }
                                New-UDTableColumn -Property ParameterValue -Title 'Value' -Render {
                                    New-UDTypography -Text $EventData.ParameterValue -Variant body2
                                }
                                New-UDTableColumn -Property Actions -Title 'Actions' -Render {
                                    New-UDButton -Text 'Remove' -Size small -Color error -Icon (New-UDIcon -Icon trash) -OnClick {
                                        $Session:LabParameters.RemoveAll({ param($p) $p.ParameterName -eq $EventData.ParameterName })
                                        Sync-UDElement -Id ParametersTable
                                        Show-UDToast -Message "Parameter '$($EventData.ParameterName)' removed!" -Duration 3000
                                    }
                                }
                            ) -Dense -Size small
                        }
                        else {
                            New-UDAlert -Severity info -Text 'No parameters added yet. Use the form on the left to add parameters.'
                        }
                    }
                } -Style @{
                    'flex'             = '1'
                    'margin-left'      = '8px'
                    'border'           = '1px solid rgba(76, 175, 80, 0.3)'
                    'background-color' = 'rgba(76, 175, 80, 0.02)'
                }
            }
        }
    } -Style @{ 
        'margin-bottom'    = '16px'
        'border'           = '1px solid rgba(33, 150, 243, 0.2)'
        'padding'          = '12px'
        'background-color' = 'rgba(232, 238, 243, 0.15)'
        'border-radius'    = '8px'
    }

    #Footer
    New-UDElement -Tag div -Attributes @{ style = @{ 'position' = 'fixed'; 'bottom' = '0'; 'left' = '0'; 'right' = '0'; 'z-index' = '1000' } } -Content {
        New-UDTypography -Text "AutomatedLab UI v1.2.0" -Variant caption -Align center -Style @{
            'padding'          = '8px 16px'
            'opacity'          = '0.7'
            'background-color' = 'rgba(0,0,0,0.05)'
            'border-top'       = '1px solid rgba(0,0,0,0.12)'
        }
    }

}
