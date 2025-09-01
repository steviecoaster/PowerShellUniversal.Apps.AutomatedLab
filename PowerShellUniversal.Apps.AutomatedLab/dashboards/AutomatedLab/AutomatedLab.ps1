New-UDApp -Title 'AutomatedLab UI' -Pages @(
    $HomePage
    $WizardPage
    $ManageLabsPage
    $NewLabPage
    $ManageISOsPage
    $CustomRolesPage
) -NavigationLayout Permanent