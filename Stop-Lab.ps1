[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $LabName
)

end {
    Stop-Lab -Name $LabName
}