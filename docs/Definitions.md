# AutomatedLab Creation Wizard

The **Create A Lab** page provides an intuitive, step-by-step wizard interface for building complete AutomatedLab definition scripts. This modern wizard guides you through lab creation with real-time validation, dynamic forms, and visual feedback.

## Overview

AutomatedLab definitions are PowerShell scripts that specify:

- Virtual machines with detailed specifications (CPU, memory, operating system)
- Virtual networking configuration (switches, subnets, IP addressing)
- Network connectivity and adapter assignments for each VM
- Complete infrastructure requirements for your lab environment

The Creation Wizard automates the generation of these scripts through a guided, 4-step process that requires no PowerShell knowledge.

## Interface Features

### Modern Wizard Design

- **Progressive Stepper**: Visual step indicator showing current progress
- **Dynamic Loading**: Automatic detection of available OS images and network adapters
- **Real-time Validation**: Immediate feedback on form inputs and configuration errors
- **Responsive Layout**: Adapts to different screen sizes and devices
- **Session Management**: Preserves your work as you navigate between steps

### Smart Data Detection

The wizard automatically loads system information:

- **Operating Systems**: Scans AutomatedLab ISO directory for available OS images
- **Network Adapters**: Detects active physical network interfaces for external switch configuration

## Step-by-Step Wizard Process

### Step 1: Lab Information

Configure the basic metadata for your lab environment.

#### Lab Configuration

**Lab Name**:

- Required field for identifying your lab
- Examples: "Active Directory Lab", "Exchange Environment", "Development Cluster"
- Used in generated script names and lab management
- Avoid special characters for compatibility

**Lab Description** _(Optional)_:

- Multi-line text field for detailed documentation
- Describes the lab's purpose, scope, and intended use
- Helpful for team environments and future reference
- Included as comments in generated scripts

### Step 2: Virtual Switch Configuration

Define the network infrastructure that connects your virtual machines.

#### Understanding Switch Types

**Default Switch (Recommended)**:

- Provides NAT-based internet connectivity
- Automatically configured by Hyper-V
- Best choice for labs requiring external internet access
- Pre-added to every new lab for convenience
- No additional configuration required

**Internal Switch**:

- Creates isolated networks between VMs only
- Requires manual IP configuration and addressing
- Best for secure, air-gapped environments
- Configuration options:
  - **Address Space**: CIDR notation (e.g., `192.168.1.0/24`)
  - **Gateway IP**: Optional gateway address (e.g., `192.168.1.1`)

**External Switch**:

- Bridges VMs directly to physical network adapters
- Provides access to your physical network infrastructure
- Automatically detects available network adapters

#### Adding Virtual Switches

1. **Enter Switch Name**: Descriptive name like "Internal", "Management", or "DMZ"
2. **Select Switch Type**: Choose from the dropdown with clear descriptions
3. **Configure Type-Specific Settings**: 
   - Internal: Address space and optional gateway fields appear
   - External: Physical adapter selection dropdown appears
   - Default Switch: No additional configuration needed
4. **Add Switch**: Click "Add Virtual Switch" to save configuration
5. **View Summary**: All configured switches appear in a detailed table

**Important**: At least one virtual switch must be defined before proceeding to VM configuration.

### Step 3: Virtual Machine Configuration

Design and configure virtual machines with detailed specifications and network connectivity.

#### VM Specification Interface

**Basic VM Information Card**:

**VM Name**:

- Unique identifier for the virtual machine
- Placeholder guidance: "e.g., DC01, WEB01, CLIENT01"
- Validation prevents duplicate names

**VM Size Templates**:

- **Small**: 2 CPU cores, 4GB RAM - Ideal for basic services
- **Medium**: 4 CPU cores, 8GB RAM - Good for most server roles
- **Large**: 8 CPU cores, 16GB RAM - High-performance applications
- **Custom**: Specify exact CPU cores and RAM requirements

**Operating System Selection**:

- Dynamically populated from `Get-LabAvailableOperatingSystem`
- Shows available Operating Systems based on discovered ISOs
- Error handling for missing ISO files with guidance to ISO management

#### Network Interface Configuration

**Network Configuration Card** _(Conditional Display)_:

- Only appears after virtual switches are configured
- Warning message if no switches are available

**Adding Network Adapters**:

1. **Virtual Switch Selection**: Dropdown showing all configured switches with network details
2. **IP Assignment Method**:
   - **DHCP (Automatic)**: Default option, no additional configuration
   - **Static IP**: Reveals static configuration fields
3. **Static IP Configuration** _(Conditional)_:
   - **IP Address**: Static IP for the interface
   - **Gateway**: Default gateway address
   - **DNS Server**: DNS server configuration
4. **Add Adapter**: Creates network interface with automatic naming (Ethernet1, Ethernet2, etc.)

**NIC Management**:

- **Live Table**: Shows all configured adapters for current VM
- **Detailed Display**: Interface name, switch assignment, IP configuration summary
- **Remove Functionality**: Individual remove buttons with automatic renumbering
- **Multiple Adapters**: Support for complex multi-homed network configurations

#### VM Creation Process

1. **Configure Basic Specifications**: Name, size, and operating system
2. **Add Network Adapters**: At least one adapter required for network connectivity
3. **Add VM to Lab**: Large, prominent button to finalize VM configuration
4. **Form Validation**: Comprehensive validation before adding VM
5. **Auto-Clear**: Form resets for adding additional VMs

#### VM Management Interface

**Defined Virtual Machines Table**:

- Shows all configured VMs with complete specifications
- Columns: Name, Size, CPU Cores, RAM, Operating System, Network Adapters
- **Network Adapter Summary**: Count and detailed connection information
- **Remove Functionality**: Individual remove buttons for each VM
- **Resource Tracking**: Visual summary of total lab resource requirements

### Step 4: Finalize Lab

Review your complete lab configuration and generate the PowerShell definition script.

#### Lab Configuration Summary

**Lab Information Panel**:

- Lab name and description
- Count of virtual switches and virtual machines
- Quick overview of lab scope and complexity

**Resources Summary Panel**:

- Total CPU cores across all VMs
- Total RAM allocation for the lab
- Resource planning information for host system requirements

#### Definition Script Generation

**Editable Code Preview**:

- **Syntax-Highlighted Editor**: Full PowerShell script with color coding
- **Customization Support**: Modify the generated script before saving
- **Real-time Generation**: Script updates based on your configuration

#### Saving and Management

**Save Lab Button**:

- Automatically saves definition to AutomatedLab configuration directory
- Downloads script file with timestamp for external storage
- Creates lab configuration entry for management interface

**Post-Save Actions** _(Revealed after saving)_:

- **Manage Labs**: Direct navigation to lab management interface
- **Start New Lab**: Reset wizard and begin creating another lab
- **Session Management**: Complete cleanup of wizard state

#### Validation and Error Prevention

**Comprehensive Validation**:

- Ensures at least one virtual switch is configured
- Requires at least one virtual machine with network connectivity
- Validates unique names for VMs and switches
- Checks resource allocation conflicts
- Provides clear error messages for resolution

## Generated Definition Structure

The Creation Wizard produces complete AutomatedLab PowerShell scripts with this structure:

```powershell
# Lab: [Your Lab Name]
# Description: [Your Description]
# Generated: [Timestamp]
# AutomatedLab UI v1.2.0

# Initialize the lab
New-LabDefinition -Name '[Lab Name]' -DefaultVirtualizationEngine HyperV

# Add virtual switches
Add-LabVirtualNetworkDefinition -Name '[Switch Name]' -VirtualizationEngine HyperV -AddressSpace '[CIDR]'

# Configure virtual machines
Add-LabMachineDefinition -Name '[VM Name]' `
    -OperatingSystem '[OS Name]' `
    -Processors [CPU Count] `
    -Memory [RAM in GB]GB `
    -Network '[Network Name]' `
    -IpAddress '[IP Address]'

# Install the lab
Install-Lab
```

## Best Practices for Using the Wizard

### Wizard Navigation Tips

**Session Persistence**:

- Your work is automatically saved as you progress through steps
- You can navigate back to previous steps to make changes
- Changes in earlier steps automatically update later configurations

**Form Management**:

- Use clear, descriptive names for labs, VMs, and switches
- Take advantage of placeholder text for formatting guidance
- Validate configurations at each step before proceeding

**Error Resolution**:

- Pay attention to validation messages and alerts
- Resolve issues immediately rather than proceeding with errors
- Use the comprehensive help text and tooltips provided

### Advanced Customization

**Script Editing**:

- The final step allows direct PowerShell script modification
- Add custom configurations not covered by the wizard
- Include additional AutomatedLab features and settings
- Modify resource allocations or add specialized configurations

**Template Creation**:

- Save generated scripts as templates for future labs
- Create standardized configurations for common lab types
- Version control definition files for team collaboration
- Document custom modifications for reuse

## Integration with Lab Management

### Workflow Integration

1. **Create Definition**: Use the wizard to build your lab script
2. **Save Configuration**: Script is saved and configuration is created automatically
3. **Manage Labs**: Navigate directly to lab management interface
4. **Start/Monitor**: Use the management interface to start and monitor lab deployment

## Troubleshooting Common Issues

### Wizard Loading Issues

#### "Loading lab configuration data..."

**Cause**: System detection of operating systems or network adapters
**Resolution**: 
- Wait for automatic detection to complete
- Check AutomatedLab ISO directory for OS files
- Verify network adapter availability

#### "No Operating Systems Available"

**Cause**: No ISO files found in AutomatedLab ISO directory
**Resolution**:
- Add ISO files to your configured ISO directory
- Use the ISO Management page to verify ISO locations
- Check AutomatedLab module installation and configuration

### Configuration Issues

#### "Please define virtual switches first"

**Cause**: Attempting to configure VMs without network infrastructure
**Resolution**:

- Return to Step 2 and configure at least one virtual switch
- Use "Add Default Switch" for quick internet-connected setup

#### "Please add network adapters"

**Cause**: Attempting to add VM without network connectivity
**Resolution**:

- Configure at least one network adapter per VM
- Select appropriate virtual switch for VM connectivity

#### "VM name already exists"

**Cause**: Duplicate VM names in configuration
**Resolution**:

- Use unique, descriptive names for each VM
- Follow consistent naming conventions (DC01, WEB02, etc.)

### Resource Planning Issues

#### Host Resource Limitations

**Cause**: Total VM resources exceed host system capabilities
**Resolution**:

- Use smaller VM size templates (Small instead of Large)
- Reduce the number of concurrent VMs
- Monitor host resource usage during lab operation

#### Network Configuration Conflicts

**Cause**: IP address conflicts or invalid network configurations
**Resolution**:

- Use proper CIDR notation for address spaces
- Ensure static IP addresses are within configured subnets
- Avoid overlapping address ranges between switches

## Related Resources

- **Lab Management**: See [Lab Management documentation](./Labs.md) for starting and monitoring created labs
- **Lab Configurations**: See [Configurations documentation](./Configurations.md) for understanding lab configuration concepts
- **Custom Roles**: See [Roles documentation](./Roles.md) for specialized machine configurations beyond the wizard
- **AutomatedLab Documentation**: Official AutomatedLab project documentation
- **AutomatedLab.Utils**: [Extended utilities and features](https://github.com/steviecoaster/automatedlab.utils)
