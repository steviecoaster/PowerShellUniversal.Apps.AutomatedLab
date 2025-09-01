# Lab Configurations

Lab Configurations provide a way to map AutomatedLab definition files to named lab instances, enabling easy management, starting, and stopping of lab environments.

## Overview

The lab configuration system consists of two main components:

- **Lab Definitions**: PowerShell scripts (`.ps1` files) that define the VMs, networking, and infrastructure for an AutomatedLab environment
- **Lab Configurations**: Named mappings that connect definition files to manageable lab instances with custom parameters

## Understanding the Workflow

1. **Create or Obtain a Definition**: Lab definitions are PowerShell scripts that specify:
   - Virtual machines and their specifications (CPU, memory, OS)
   - Network topology and configuration
   - Software installations and configurations
   - Domain controllers, clients, and specialized roles

2. **Create a Lab Configuration**: The `New Configuration` page allows you to:
   - Give your lab a meaningful name
   - Map it to a definition file (local file or URL)
   - Add and manage custom parameters for the definition
   - Save the configuration for easy lab management

## Using the New Lab Configuration Page

### Step-by-Step Process

1. **Navigate to New Configuration**: Open the `New Configuration` page from the navigation menu

2. **Review the Information**:
   - The top section explains what lab configurations are
   - Includes helpful tips about PowerShell-based definitions
   - Provides context for why parameters are useful

3. **Provide Lab Details**:
   - **Lab Name**: Enter a descriptive name for your lab instance in the text field
   - **Definition Type**: Choose from the dropdown:
     - 📁 **File**: Path to a local `.ps1` definition file
     - 🌐 **URL**: Link to a hosted definition file (e.g., GitHub, web server)
   - **Definition Location**: Enter the file path or URL in the text field

4. **Manage Parameters** (Optional):
   The interface provides a split-view parameter management system:
   
   **Left Panel - Add Parameters**:
   - Enter parameter name and value in the provided fields
   - Click "Add Parameter" to save the parameter
   - The system prevents duplicate parameter names and updates existing ones
   - Visual feedback confirms when parameters are added or updated
   
   **Right Panel - Current Parameters**:
   - View all added parameters in a clean table format
   - See parameter names and their values at a glance
   - Remove individual parameters using the trash icon
   - Empty state message when no parameters are configured

5. **Create Configuration**: Click `Create Configuration` to save your lab configuration

### UI Features

- **Visual Feedback**: Toast notifications provide immediate feedback for all actions
- **Input Validation**: Required fields are validated before submission
- **Real-time Updates**: Parameter table updates immediately when parameters are added/removed
- **Responsive Design**: Layout adapts to different screen sizes
- **Clear Organization**: Logical grouping of related functions with visual hierarchy

### What Happens Next

Once created, your lab configuration will be available in the **Manage Labs** page where you can:

- Start and stop the entire lab environment
- View VM details and status
- Monitor lab resources
- Access individual lab components

## Lab Definition Requirements

Lab definitions should be PowerShell scripts that:

- Use AutomatedLab cmdlets to define infrastructure
- Accept parameters via `param()` blocks if customization is needed
- Follow AutomatedLab scripting conventions
- Include proper error handling and validation

### Example Definition Structure

```powershell
param(
    [string]$DomainName = "contoso.com",
    [int]$ClientCount = 2
)

# Define lab infrastructure
New-Lab -Name "MyLab" -DefaultVirtualizationEngine HyperV

# Add domain controller
Add-LabMachineDefinition -Name "DC01" -OperatingSystem "Windows Server 2022" -Roles RootDC

# Add client machines
for ($i = 1; $i -le $ClientCount; $i++) {
    Add-LabMachineDefinition -Name "Client$i" -OperatingSystem "Windows 11"
}

Install-Lab
```

## Best Practices

### Naming Conventions

- Use descriptive lab names that indicate purpose: "Exchange-Lab", "AD-Testing", "Development-Environment"
- Avoid special characters and spaces in lab names

### Parameter Management

- Document required and optional parameters in your definition files
- Use meaningful parameter names and default values
- Validate parameter inputs in your definitions

### File Organization

- Store definition files in a consistent location
- Use version control for definition files
- Consider using URLs for shared definitions across teams

## Troubleshooting

### Common Issues

#### Definition File Not Found

- Verify the file path is correct and accessible
- Check file permissions if using local files
- Ensure URLs are accessible and return valid PowerShell content

#### Parameter Errors

- Verify parameter names match those expected by the definition
- Check parameter data types and format
- Review definition file for required vs. optional parameters

#### Lab Creation Failures

- Check the definition file syntax for PowerShell errors
- Verify AutomatedLab module dependencies
- Review system resources and virtualization requirements

## Related Resources

- **Definitions Documentation**: [AutomatedLab.Utils Definitions](https://github.com/steviecoaster/automatedlab.utils/blob/main/Definitions.md)
- **AutomatedLab Documentation**: Official AutomatedLab project documentation
- **Custom Roles**: See the [Roles documentation](./Roles.md) for creating specialized machine configurations