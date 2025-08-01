# New-PSUScript -Module "AutomatedLab.PowerShellUniversal" -Command "Get-PSULabConfiguration" 
# New-PSUScript -Module "AutomatedLab.Utils" -Command "New-LabConfiguration" 
New-PSUScript -Name "Start-Lab.ps1" -Description "Starts a Lab in AutomatedLab" -Path "Start-Lab.ps1" -Environment "PowerShell 7" 
New-PSUScript -Name "Stop-Lab.ps1" -Description "Stops a lab in Automated Lab" -Path "Stop-Lab.ps1" -Environment "PowerShell 7"