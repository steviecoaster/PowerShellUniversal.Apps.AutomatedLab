$HomePage = New-UDPage -Url "/Home" -Name "Home" -Content {
    New-UDImage -Url "https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/develop/Assets/AutomatedLab2025-LOGOFORWEB_256_white.png"

    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -MediumSize 12 -LargeSize 12 -Content {
            New-UDTypography -Variant h3 -Text "AutomatedLab UI" -Align "center"
        }
    }
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -MediumSize 12 -LargeSize 12 -Content {
            New-UDTypography -Variant h6 -Text "Web based lab management" -Align "center"
        }
    }
    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -MediumSize 6 -LargeSize 4 -Content {
            New-UDCard -Title "Manage Labs" -Content {
                New-UDStack -Direction row -Spacing 2 -Content {
                    New-UDIcon -Icon server -Size lg
                    New-UDTypography -Text "Lab Management" -Variant body1
                }
                New-UDButton -Text "Open Lab Manager" -Color primary -OnClick {
                    # Add your VM management logic here
                    Invoke-UDRedirect -Url '/Manage-Labs'
                }
            } -Style @{
                'text-align' = 'center'
                'margin'     = '10px'
            }
        }

        New-UDColumn -SmallSize 12 -MediumSize 6 -LargeSize 4 -Content {
            New-UDCard -Title "Add Lab Configuration" -Content {
                New-UDStack -Direction row -Spacing 2 -Content {
                    New-UDIcon -Icon file-code  -Size lg
                    New-UDTypography -Text "Configuration" -Variant body1
                }
                New-UDButton -Text "Open Configuration Management" -Color primary -OnClick {
                    # Add your VM management logic here
                    Invoke-UDRedirect -Url '/New-Lab'
                }
            } -Style @{
                'text-align' = 'center'
                'margin'     = '10px'
            }
        }
    }

    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -MediumSize 6 -LargeSize 4 -Content {
            New-UDCard -Title "Manage ISOs" -Content {
                New-UDStack -Direction row -Spacing 2 -Content {
                    New-UDIcon -Icon 'compact-disc' -Size lg
                    New-UDTypography -Text "ISO Management" -Variant body1
                }
                New-UDButton -Text "Open ISO Manager" -Color primary -OnClick {
                    # Add your VM management logic here
                    Invoke-UDRedirect -Url '/Manage-Isos'
                }
            } -Style @{
                'text-align' = 'center'
                'margin'     = '10px'
            }
        }

        New-UDColumn -SmallSize 12 -MediumSize 6 -LargeSize 4 -Content {
            New-UDCard -Title "Add Custom Role" -Content {
                New-UDStack -Direction row -Spacing 2 -Content {
                    New-UDIcon -Icon puzzle-piece  -Size lg
                    New-UDTypography -Text "Roles" -Variant body1
                }
                New-UDButton -Text "Open Role Management" -Color primary -OnClick {
                    # Add your VM management logic here
                    Invoke-UDRedirect -Url '/Custom-Roles'
                }
            } -Style @{
                'text-align' = 'center'
                'margin'     = '10px'
            }
        }
    }

    New-UDRow -Columns {
        New-UDColumn -SmallSize 12 -MediumSize 6 -LargeSize 4 -Content {
            New-UDCard -Title "New Definition" -Content {
                New-UDStack -Direction row -Spacing 2 -Content {
                    New-UDIcon -Icon 'file-code' -Size lg
                    New-UDTypography -Text "Definition Builder" -Variant body1
                }
                New-UDButton -Text "Create Definition" -Color primary -OnClick {
                    # Add your VM management logic here
                    Invoke-UDRedirect -Url '/New-Definition'
                }
            } -Style @{
                'text-align' = 'center'
                'margin'     = '10px'
            }
        }
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