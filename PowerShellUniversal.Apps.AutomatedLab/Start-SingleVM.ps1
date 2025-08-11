[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $LabVM
)

end {
    Start-LWHypervVM -ComputerName $LabVM -TimeoutInMinutes 5
}