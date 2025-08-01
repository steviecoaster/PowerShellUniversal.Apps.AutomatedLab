[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $LabName
)

end {
    Start-Lab -Name $LabName
}