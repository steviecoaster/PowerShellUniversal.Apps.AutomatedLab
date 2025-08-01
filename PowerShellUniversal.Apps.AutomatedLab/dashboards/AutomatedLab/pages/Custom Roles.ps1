$CustomRolesPage = New-UDPage -Url "/Custom-Roles" -Name "Custom Roles" -Content {
    $Script:CustomRoleFiles = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()


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
                        New-UDTypography -Text "Create New Custom Role" -Variant h5
                        New-UDElement -Tag "br"
                        New-UDTextbox -Id "RoleName" -Label "Role Name" -Placeholder "Enter role name"
                        New-UDElement -Tag "br"
                    
                        # Init script handling
                        New-UDTypography -Text 'Initialization Script' -Variant h6
                        New-UDStack -Direction row -Spacing 5 -AlignItems center -Content {
                            New-UDSelect -Id "InitScriptType" -Option {
                                New-UDSelectOption -Name 'File' -Value 'File'
                                New-UDSelectOption -Name 'Url' -Value 'Url'
                            } -DefaultValue 'File'
                            New-UDTextbox -Id 'InitScript' -Placeholder 'Init script location'
                        }
                        New-UDElement -Tag "br"
                        
                        # File Management Section
                        New-UDTypography -Text 'Additional Files' -Variant h6
                        New-UDStack -Direction row -Spacing 2 -AlignItems center -Content {
                            New-UDTextbox -Id 'FilePath' -Placeholder 'Enter file path to add'
                            New-UDButton -Text "Add File" -Color secondary -Size small -OnClick {
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
                                    $Script:CustomRoleFiles.Add($file)
                                    
                                    # Clear textbox and refresh table
                                    Set-UDElement -Id 'FilePath' -Properties @{ value = "" }
                                    Sync-UDElement -Id 'FilesTable'
                                    Show-UDToast -Message "File added successfully"
                                }
                                catch {
                                    Show-UDToast -Message "Error adding file: $($_.Exception.Message)"
                                }
                            }
                        }
                        
                        # Files Table
                        New-UDDynamic -Id 'FilesTable' -Content {
                            if ($Script:CustomRoleFiles -and $Script:CustomRoleFiles.Count -gt 0) {
                                $columns = @(
                                    New-UDTableColumn -Property Name -Title "File Name" -Render {
                                        New-UDStack -Direction row -Spacing 1 -AlignItems center -Content {
                                        
                                            New-UDIcon -Icon file -Size sm -Color primary
                                            New-UDTypography -Text $EventData.Name -Variant body2
                                        }
                                    }
                                    New-UDTableColumn -Property Size -Title "Size" -Render {
                                        New-UDTypography -Text "$([Math]::Round(( $EventData.Length / 1kb),2))KB" -Variant body2
                                    }
                                    New-UDTableColumn -Property Type -Title "Type" -Render {
                                        if ($EventData.PSIsContainer -eq "True") {
                                            New-UDChip -Label "Folder" -Color default -Size small
                                        }
                                        else {
                                            New-UDChip -Label 'File' -Color primary -Size small -Variant outlined
                                        }
                                    }
                                    New-UDTableColumn -Property Actions -Title "Actions" -Render {
                                        New-UDButton -Text "Remove" -Color error -Size small -Variant outlined -OnClick {
                                            # Find and remove the item from the List collection
                                            #$itemToRemove = $Script:CustomRoleFiles | Where-Object { $_.FullName -eq $EventData }
                                            Show-UDToast -Message $Script:CustomRoleFiles
                                            if ($itemToRemove) {
                                                Show-UDToast -Message "Will remove: $itemToRemove"
                                                $Script:CustomRoleFiles.Remove($itemToRemove)
                                                Sync-UDElement -Id 'FilesTable'
                                                Show-UDToast -Message 'File removed successfully!'
                                            }
                                            else {
                                                Show-UDToast -Message "File not found in collection"
                                            }
                                        } -Icon (New-UDIcon -Icon trash)
                                    }
                                )
                                
                                New-UDCard -Content {
                                    New-UDTypography -Text "Files to Include ($($Script:CustomRoleFiles.Count))" -Variant subtitle2 -Style @{ 'margin-bottom' = '8px' }
                                    New-UDTable -Data $Script:CustomRoleFiles -Id 'AdditionalFilesTableData' -Columns $columns -Dense -PageSize 5
                                } -Style @{ 'margin-top' = '12px'; 'background-color' = 'rgba(76, 175, 80, 0.04)' }
                            }
                            else {
                                New-UDCard -Content {
                                    New-UDTypography -Text "No additional files added" -Variant body2 -Align center -Style @{ 'opacity' = '0.6'; 'padding' = '16px' }
                                } -Style @{ 'margin-top' = '12px'; 'border' = '1px dashed rgba(0,0,0,0.12)' }
                            }
                        }
                    } -SubmitText 'Create Role' -OnSubmit {
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
                            Show-UDToast -Message "Role Name is required"
                            return
                        }
                        
                        try {
                            # Prepare parameters for New-CustomRole
                            $Params = @{
                                Name = $RoleName.Trim()
                            }
                            
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
                            if ($Script:CustomRoleFiles -and $Script:CustomRoleFiles.Count -gt 0) {
                                $Params.AdditionalFiles = $Script:CustomRoleFiles.FullName
                            }
                            
                            $additionalData = Get-UDElement -Id 'AdditionalFilesTableData'
                            Show-UDToast -Message ($Script:CustomRoleFiles.FullName)
                            # Create the custom role
                            New-CustomRole @Params
                            
                            # Clear the files collection after successful creation
                            $Script:CustomRoleFiles.Clear()
                            
                            Show-UDToast -Message "Custom role '$RoleName' created successfully!"
                            Hide-UDModal
                            Sync-UDElement -Id CustomRolesTable
                            
                        }
                        catch {
                            Show-UDToast -Message "Error creating custom role: $($_.Exception.Message)"
                        }
                    }
                    
                } -Header {
                    New-UDTypography -Text "Add Custom Role" -Variant h4
                }
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
                                    $initScriptPath = Join-Path $rolePath $expectedInitScript
                                    $initScriptExists = Test-Path $initScriptPath
                                    
                                    try {
                                        $filesCount = (Get-ChildItem -Path $rolePath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
                                    }
                                    catch {
                                        $filesCount = 0
                                    }
                                    
                                    [PSCustomObject]@{
                                        Name         = $role.Name
                                        Path         = $rolePath
                                        InitScript   = if ($initScriptExists) { $expectedInitScript } else { "Missing" }
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
                                    New-UDChip -Label "$($EventData.FilesCount) files" -Color default -Variant default
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
                                                    
                                                        Show-UDToast -Message "Custom role '$($EventData.Name)' removed successfully!"
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
                                    New-UDIcon -Icon cogs -Size '3x' -Color disabled -Style @{ 'opacity' = '0.5' }
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
        New-UDTypography -Text "AutomatedLab UI v1.0.0" -Variant caption -Align center -Style @{
            'padding'          = '8px 16px'
            'opacity'          = '0.7'
            'background-color' = 'rgba(0,0,0,0.05)'
            'border-top'       = '1px solid rgba(0,0,0,0.12)'
        }
    }
}