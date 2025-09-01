$CustomRolesPage = New-UDPage -Url "/Custom-Roles" -Name "Custom Roles" -Content {
    $Session:CustomRoleFiles = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()

    # Header section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDCard -Content {
                New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                    New-UDIcon -Icon cogs -Size '2x' -Color primary
                    New-UDStack -Direction column -Content {
                        New-UDTypography -Variant h4 -Text "Custom Roles" -Style @{ 'margin-bottom' = '4px' }
                        New-UDTypography -Variant subtitle1 -Text "Add/Remove Custom Roles for your AutomatedLab environment" -Style @{ 'opacity' = '0.8' }
                    }
                }
            } -Style @{ 
                'margin-bottom' = '24px'
                'background'    = 'linear-gradient(135deg, rgba(156, 39, 176, 0.1) 0%, rgba(156, 39, 176, 0.05) 100%)'
                'border-left'   = '4px solid #9C27B0'
            }
        }
    }

    # Add Custom Role Button and Modal
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDButton -Text "Add Custom Role" -Color primary -OnClick {
                # Reset the files collection when opening modal
                
                Show-UDModal -Content {
                    New-UDForm -Id "CustomRoleForm" -Content {
                        # Card 1: Information about roles
                        New-UDCard -Content {
                            New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                                New-UDIcon -Icon info-circle -Size lg -Color info
                                New-UDStack -Direction column -Content {
                                    New-UDTypography -Variant h6 -Text "About Custom Roles" -Style @{ 'margin-bottom' = '8px'; 'color' = '#1976d2' }
                                    New-UDTypography -Variant body2 -Text "Custom roles define reusable configurations that can be applied to VMs during lab creation. Each role can include initialization scripts and additional files that will be deployed automatically." -Style @{ 'line-height' = '1.5' }
                                }
                            }
                        } -Style @{ 
                            'margin-bottom' = '16px'
                            'background' = 'linear-gradient(135deg, rgba(25, 118, 210, 0.08) 0%, rgba(25, 118, 210, 0.04) 100%)'
                            'border-left' = '4px solid #1976d2'
                        }

                        # Card 2: Role Name
                        New-UDCard -Content {
                            New-UDStack -Direction column -Spacing 2 -Content {
                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                    New-UDIcon -Icon tag -Size sm -Color primary
                                    New-UDTypography -Variant h6 -Text "Role Identification" -Style @{ 'color' = '#9C27B0' }
                                }
                                New-UDTypography -Variant body2 -Text "Choose a descriptive name for your custom role. This name will be used to identify the role in your lab configurations." -Style @{ 'margin-bottom' = '12px'; 'opacity' = '0.8' }
                                New-UDTextbox -Id "RoleName" -Label "Role Name" -Placeholder "e.g., WebServer, DomainController, DatabaseServer" -FullWidth -Icon (New-UDIcon -Icon cogs)
                            }
                        } -Style @{ 
                            'margin-bottom' = '16px'
                            'background-color' = 'rgba(156, 39, 176, 0.04)'
                            'border' = '1px solid rgba(156, 39, 176, 0.2)'
                        }

                        # Card 3: Initialization Script
                        New-UDCard -Content {
                            New-UDStack -Direction column -Spacing 2 -Content {
                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                    New-UDIcon -Icon code -Size sm -Color success
                                    New-UDTypography -Variant h6 -Text "Initialization Script" -Style @{ 'color' = '#4CAF50' }
                                }
                                New-UDTypography -Variant body2 -Text "Define how your role should be initialized. You can specify a local PowerShell script file or provide a URL to download a script from the internet." -Style @{ 'margin-bottom' = '12px'; 'opacity' = '0.8' }
                                New-UDGrid -Container -Spacing 2 -Content {
                                    New-UDGrid -Item -SmallSize 4 -Content {
                                        New-UDSelect -Id "InitScriptType" -Label "Script Source" -FullWidth -Option {
                                            New-UDSelectOption -Name 'Local File' -Value 'File'
                                            New-UDSelectOption -Name 'URL Download' -Value 'Url'
                                        } -DefaultValue 'File' -Icon (New-UDIcon -Icon file-code)
                                    }
                                    New-UDGrid -Item -SmallSize 8 -Content {
                                        New-UDTextbox -Id 'InitScript' -Label "Script Location" -Placeholder 'C:\Scripts\MyRole.ps1 or https://example.com/script.ps1' -FullWidth -Icon (New-UDIcon -Icon link)
                                    }
                                }
                            }
                        } -Style @{ 
                            'margin-bottom' = '16px'
                            'background-color' = 'rgba(76, 175, 80, 0.04)'
                            'border' = '1px solid rgba(76, 175, 80, 0.2)'
                        }

                        # Card 4: Additional Files
                        New-UDCard -Content {
                            New-UDStack -Direction column -Spacing 2 -Content {
                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                    New-UDIcon -Icon folder-open -Size sm -Color warning
                                    New-UDTypography -Variant h6 -Text "Additional Files" -Style @{ 'color' = '#FF9800' }
                                }
                                New-UDTypography -Variant body2 -Text "Include additional files or folders that should be deployed with this role. These files will be copied to the target VMs when the role is applied." -Style @{ 'margin-bottom' = '12px'; 'opacity' = '0.8' }
                                New-UDGrid -Container -Spacing 1 -Content {
                                    New-UDGrid -Item -SmallSize 8 -Content {
                                        New-UDTextbox -Id 'FilePath' -Label "File or Folder Path" -Placeholder 'C:\MyFiles\config.xml or C:\MyFolder\' -FullWidth -Icon (New-UDIcon -Icon folder)
                                    }
                                    New-UDGrid -Item -SmallSize 4 -Content {
                                        New-UDButton -Text "Add File" -Color warning -Size medium -FullWidth -OnClick {
                                            $filePath = (Get-UDElement -Id 'FilePath').value -replace '"', ''
                                            
                                            if ([string]::IsNullOrWhiteSpace($filePath)) {
                                                Show-UDToast -Message "Please enter a file path" 
                                                return
                                            }
                                            
                                            if (-not (Test-Path $filePath)) {
                                                Show-UDToast -Message "File does not exist: $filePath" 
                                                return
                                            }
                                            
                                            try {
                                                $file = Get-Item $filePath
                                                $Session:CustomRoleFiles.Add($file)
                                                
                                                # Clear textbox and refresh table
                                                Set-UDElement -Id 'FilePath' -Properties @{ value = "" }
                                                Sync-UDElement -Id 'FilesTable'
                                            }
                                            catch {
                                                Show-UDToast -Message "Error adding file: $($_.Exception.Message)" 
                                            }
                                        } -Icon (New-UDIcon -Icon plus)
                                    }
                                }
                                
                                # Files Table
                                New-UDDynamic -Id 'FilesTable' -Content {
                                    if ($Session:CustomRoleFiles -and $Session:CustomRoleFiles.Count -gt 0) {
                                        $columns = @(
                                            New-UDTableColumn -Property Name -Title "File Name" -Render {
                                                New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                                    New-UDIcon -Icon file -Size sm -Color primary
                                                    New-UDTypography -Text $EventData.Name -Variant body2 -Style @{ 'font-weight' = '500' }
                                                }
                                            }
                                            New-UDTableColumn -Property Length -Title "Size" -Render {
                                                if ($EventData.PSIsContainer) {
                                                    New-UDChip -Label "Folder" -Color default -Size small
                                                }
                                                else {
                                                    try {
                                                        
                                                        if ($EventData.Length -and $EventData.Length -gt 0) {
                                                            $sizeMB = [Math]::Round(($EventData.Length / 1mb), 2)
                                                            New-UDChip -Label "$sizeMB MB" -Color default -Size small
                                                        } else {
                                                            New-UDChip -Label "0 KB" -Color default -Size small
                                                        }
                                                    }
                                                    catch {
                                                        New-UDChip -Label "N/A" -Color default -Size small
                                                    }
                                                }
                                            }
                                            New-UDTableColumn -Property Type -Title "Type" -Render {
                                                if ($EventData.PSIsContainer) {
                                                    New-UDChip -Label "Folder" -Color info -Size small -Icon (New-UDIcon -Icon folder)
                                                }
                                                else {
                                                    New-UDChip -Label 'File' -Color primary -Size small -Variant outlined -Icon (New-UDIcon -Icon file)
                                                }
                                            }
                                            New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                                New-UDButton -Text "Remove" -Color error -Size small -Variant outlined -OnClick {
                                                    # Find and remove the item from the List collection
                                                    Show-UDToast -Message $EventData
                                                    $itemToRemove = $Session:CustomRoleFiles | Where-Object { $_.FullName -eq $EventData }
                                                    if ($itemToRemove) {
                                                        $Session:CustomRoleFiles.Remove($itemToRemove)
                                                        Sync-UDElement -Id 'FilesTable'
                                                    }
                                                    else {
                                                        Show-UDToast -Message "File not found in collection" 
                                                    }
                                                } -Icon (New-UDIcon -Icon trash)
                                            }
                                        )
                                        
                                        New-UDCard -Content {
                                            New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                                New-UDIcon -Icon files -Size sm -Color success
                                                New-UDTypography -Text "Files to Include ($($Session:CustomRoleFiles.Count))" -Variant subtitle2 -Style @{ 'color' = '#4CAF50'; 'font-weight' = 'bold' }
                                            }
                                            New-UDTable -Data $Session:CustomRoleFiles -Id 'AdditionalFilesTableData' -Columns $columns -Dense -PageSize 5
                                        } -Style @{ 'margin-top' = '12px'; 'background-color' = 'rgba(76, 175, 80, 0.08)'; 'border' = '1px solid rgba(76, 175, 80, 0.3)' }
                                    }
                                    else {
                                        New-UDCard -Content {
                                            New-UDStack -Direction column -Spacing 1 -AlignItems center -Content {
                                                New-UDIcon -Icon file-plus -Size lg -Color disabled
                                                New-UDTypography -Text "No additional files added" -Variant body2 -Align center -Style @{ 'opacity' = '0.6'; 'font-weight' = '500' }
                                                New-UDTypography -Text "Files are optional but can enhance your role's functionality" -Variant caption -Align center -Style @{ 'opacity' = '0.5' }
                                            }
                                        } -Style @{ 'margin-top' = '12px'; 'border' = '2px dashed rgba(0,0,0,0.12)'; 'padding' = '20px'; 'text-align' = 'center' }
                                    }
                                }
                            }
                        } -Style @{ 
                            'background-color' = 'rgba(255, 152, 0, 0.04)'
                            'border' = '1px solid rgba(255, 152, 0, 0.2)'
                        }
                    } -SubmitText 'Create Role' -ButtonVariant contained -OnSubmit {
                    
                        # Get form values from EventData
                        $RoleName = $EventData.RoleName
                        $InitScriptType = $EventData.InitScriptType
                        $InitScript = if ($InitScriptType -eq 'File') {
                            $EventData.InitScript -replace '"', ''
                        }
                        else {
                            $EventData.InitScript
                        }
                    
                        
                        # Validate required field
                        if ([string]::IsNullOrWhiteSpace($RoleName)) {
                            Show-UDToast -Message "Role Name is required - value was empty or null" -Duration 5000
                            return
                        }
                        
                        try {
                        
                            # Prepare parameters for New-CustomRole
                            $Params = @{}
                                                    
                            # Add script parameter based on type
                            if ($InitScriptType -ne 'None' -and -not [string]::IsNullOrWhiteSpace($InitScript)) {
                                if ($InitScriptType -eq 'File') {
                                    $Params.InitScript = $InitScript.Trim()
                                }
                                elseif ($InitScriptType -eq 'Url') {
                                    $Params.InitUrl = $InitScript.Trim()
                                }
                            }
                            
                            # Add additional files if any were selected
                            if ($Session:CustomRoleFiles -and $Session:CustomRoleFiles.Count -gt 0) {
                                $Params.AdditionalFiles = $Session:CustomRoleFiles.FullName
                            }
                        
                            # Create the custom role
                            New-CustomRole -Name $RoleName @Params
                            
                            # Clear the files collection after successful creation
                            $Session:CustomRoleFiles.Clear()
                            
                            Hide-UDModal
                            Sync-UDElement -Id CustomRolesTable
                            
                        }
                        catch {
                            Show-UDToast -Message "Error creating custom role: $($_.Exception.Message)" 
                        }
                    }
                    
                } -Header {
                    New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                        New-UDIcon -Icon plus-circle -Size lg -Color primary
                        New-UDTypography -Text "Create New Custom Role" -Variant h4 -Style @{ 'color' = '#9C27B0' }
                    }
                } -MaxWidth 'lg' -FullWidth
            }
        }
    }

    # Custom Roles table section
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -Content {
            New-UDDynamic -Id CustomRolesTable -Content {
                try {
                    $customRolesPath = "C:\LabSources\CustomRoles\"
                    
                    if (Test-Path $customRolesPath) {
                        $customRoles = Get-ChildItem -Path $customRolesPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $true }
                    
                        if ($customRoles -and $customRoles.Count -gt 0) {
                            $roleData = foreach ($role in $customRoles) {
                                # Ensure we're working with a DirectoryInfo object
                                if ($role -is [System.IO.DirectoryInfo]) {
                                    $rolePath = $role.FullName
                                    $expectedInitScript = "$($role.Name).ps1"
                                    $builtinScript = 'HostStart.ps1'
                                    $initScriptPath = Join-Path $rolePath $expectedInitScript
                                    $builtinScriptPath = Join-Path $rolePath $builtinScript
                                    $initScriptExists = Test-Path $initScriptPath
                                    $builtinScriptExists = Test-Path $builtinScriptPath
                                    
                                    try {
                                        $filesCount = (Get-ChildItem -Path $rolePath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
                                    }
                                    catch {
                                        $filesCount = 0
                                    }
                                    
                                    [PSCustomObject]@{
                                        Name         = $role.Name
                                        Path         = $rolePath
                                        InitScript   = if ($initScriptExists) { $expectedInitScript } elseif ($builtinScriptExists) { $builtinScript } else { "Missing" }
                                        FilesCount   = $filesCount
                                        Created      = $role.CreationTime
                                        LastModified = $role.LastWriteTime
                                    }
                                }
                            }
                            
                            $Columns = @(
                                New-UDTableColumn -Property Name -Title "Role Name" -Render {
                                    New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                        New-UDIcon -Icon cogs -Size sm -Color primary
                                        New-UDTypography -Text $EventData.Name -Variant body1 -Style @{ 'font-weight' = '500' }
                                    }
                                }
                                New-UDTableColumn -Property InitScript -Title "Init Script" -Render {
                                    if ($EventData.InitScript -eq "Missing") {
                                        New-UDChip -Label "Missing" -Color error -Variant outlined
                                    }
                                    elseif ($EventData.InitScript -ne "None") {
                                        New-UDChip -Label $EventData.InitScript -Color success -Variant outlined
                                    }
                                    else {
                                        New-UDTypography -Text "None" -Variant body2 -Style @{ 'opacity' = '0.6' }
                                    }
                                }
                                New-UDTableColumn -Property FilesCount -Title "Files" -Render {
                                    New-UDChip -Label "$($EventData.FilesCount) files" -Color default
                                }
                                New-UDTableColumn -Property Created -Title "Created" -Render {
                                    New-UDTypography -Text $EventData.Created.ToString("yyyy-MM-dd HH:mm") -Variant body2
                                }
                                New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                    New-UDStack -Direction row -Spacing 1 -Content {
                                        New-UDButton -Text "Details" -Color primary -Size small -Variant outlined -OnClick {
                                            $RoleDetails = $EventData
                                            Show-UDModal -Content {
                                                New-UDCard -Content {
                                                    New-UDTypography -Variant h5 -Text "Custom Role Details" -Style @{ 'margin-bottom' = '20px'; 'color' = '#9C27B0'; 'text-align' = 'center' }
                                                
                                                    # Basic Information
                                                    New-UDCard -Content {
                                                        New-UDTypography -Variant h6 -Text "Basic Information" -Style @{ 'margin-bottom' = '12px' }
                                                        New-UDRow -Columns {
                                                            New-UDColumn -SmallSize 6 -Content {
                                                                New-UDTypography -Text "Name:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                                New-UDTypography -Text $RoleDetails.Name -Variant body1
                                                            }
                                                            New-UDColumn -SmallSize 6 -Content {
                                                                New-UDTypography -Text "Files Count:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold' }
                                                                New-UDTypography -Text $RoleDetails.FilesCount -Variant body1
                                                            }
                                                        }
                                                        New-UDRow -Columns {
                                                            New-UDColumn -SmallSize 12 -Content {
                                                                New-UDTypography -Text "Path:" -Variant subtitle2 -Style @{ 'font-weight' = 'bold'; 'margin-top' = '8px' }
                                                                New-UDTypography -Text $RoleDetails.Path -Variant body2 -Style @{ 'font-family' = 'monospace'; 'word-break' = 'break-all' }
                                                            }
                                                        }
                                                    } -Style @{ 'background-color' = 'rgba(156, 39, 176, 0.04)'; 'padding' = '12px'; 'margin-bottom' = '16px' }
                                                
                                                    # Files List
                                                    $roleFiles = Get-ChildItem -Path $RoleDetails.Path -File -Recurse
                                                    if ($roleFiles) {
                                                        New-UDCard -Content {
                                                            New-UDTypography -Variant h6 -Text "Files" -Style @{ 'margin-bottom' = '12px' }
                                                            foreach ($file in $roleFiles) {
                                                                New-UDTypography -Text "• $($file.Name)" -Variant body2 -Style @{ 'font-family' = 'monospace'; 'margin-left' = '8px' }
                                                            }
                                                        } -Style @{ 'background-color' = 'rgba(76, 175, 80, 0.04)'; 'padding' = '12px' }
                                                    }
                                                } -Style @{ 'max-width' = '600px'; 'margin' = 'auto' }
                                            } -Header {
                                                New-UDTypography -Text "Role: $($RoleDetails.Name)" -Variant h6
                                            } -Footer {
                                                New-UDButton -Text "Close" -Color primary -OnClick {
                                                    Hide-UDModal
                                                }
                                            } -FullWidth -MaxWidth 'md'
                                        } -Icon (New-UDIcon -Icon info-circle)
                                    
                                        New-UDButton -Text "Remove" -Color error -Size small -Variant outlined -OnClick {
                                            Show-UDModal -Content {
                                                New-UDTypography -Text "Are you sure you want to remove this custom role?" -Variant h6 -Align center
                                                New-UDTypography -Text $EventData.Name -Variant body1 -Align center -Style @{ 'margin' = '16px 0'; 'font-weight' = 'bold' }
                                                New-UDTypography -Text "This action will delete the entire role directory and cannot be undone." -Variant body2 -Align center -Style @{ 'color' = '#f44336' }
                                            } -Header {
                                                New-UDTypography -Text "Confirm Removal" -Variant h6
                                            } -Footer {
                                                New-UDButton -Text "Cancel" -OnClick { Hide-UDModal }
                                                New-UDButton -Text "Remove Role" -Color error -OnClick {
                                                    try {
                                                        Remove-Item -Path $EventData.Path -Recurse -Force
                                                    
                                                        Hide-UDModal
                                                        Sync-UDElement -Id CustomRolesTable
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Failed to remove role: $($_.Exception.Message)"
                                                    }
                                                }
                                            } -MaxWidth 'sm'
                                        } -Icon (New-UDIcon -Icon trash)
                                    }
                                }
                            )
                        
                            New-UDCard -Content {
                                New-UDTypography -Variant h6 -Text "Custom Roles" -Style @{ 'margin-bottom' = '16px' }
                                New-UDTable -Data $roleData -Columns $Columns -Dense -ShowSearch -ShowPagination -PageSize 10 -Sort
                            } -Style @{ 'box-shadow' = '0 4px 6px rgba(0, 0, 0, 0.1)' }
                        }
                        else {
                            # Empty state
                            New-UDCard -Content {
                                New-UDStack -Direction column -Spacing 2 -AlignItems center -Content {
                                    New-UDIcon -Icon cogs -Size '3x' -Color disabled
                                    New-UDTypography -Variant h6 -Text "No Custom Roles Found" -Align center
                                    New-UDTypography -Variant body2 -Text "Create your first custom role to get started." -Align center -Style @{ 'opacity' = '0.7' }
                                }
                            } -Style @{ 
                                'text-align' = 'center'
                                'padding'    = '40px'
                                'border'     = '2px dashed rgba(0,0,0,0.12)'
                            }
                        }
                    }
                    else {
                        # Directory doesn't exist
                        New-UDCard -Content {
                            New-UDStack -Direction column -Spacing 2 -AlignItems center -Content {
                                New-UDIcon -Icon exclamation-triangle -Size '2x' -Color warning
                                New-UDTypography -Variant h6 -Text "CustomRoles Directory Not Found" -Align center
                                New-UDTypography -Variant body2 -Text "The directory C:\LabSources\CustomRoles\ does not exist." -Align center -Style @{ 'opacity' = '0.7' }
                            }
                        } -Style @{ 
                            'text-align'       = 'center'
                            'padding'          = '40px'
                            'background-color' = 'rgba(255, 193, 7, 0.04)'
                            'border'           = '2px dashed rgba(255, 193, 7, 0.3)'
                        }
                    }
                }
                catch {
                    New-UDCard -Content {
                        New-UDTypography -Variant h6 -Text "Error Loading Custom Roles" -Style @{ 'color' = '#f44336'; 'margin-bottom' = '8px' }
                        New-UDTypography -Text "Failed to retrieve custom roles: $($_.Exception.Message)" -Variant body2 -Style @{ 'color' = '#f44336' }
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