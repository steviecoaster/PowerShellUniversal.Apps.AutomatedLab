[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $LabVM
)

end {
    Stop-LWHypervVM -ComputerName $LabVM -TimeoutInMinutes 5
}