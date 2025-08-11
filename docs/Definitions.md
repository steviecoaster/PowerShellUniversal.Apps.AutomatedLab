# AutomatedLab Definition Builder

The **New Definition** page provides a graphical, step-by-step interface for creating AutomatedLab definition scripts. This wizard-based approach helps you design lab environments without writing PowerShell code directly.

## Overview

AutomatedLab definitions are PowerShell scripts that specify:

- Virtual machines and their specifications (CPU, memory, operating system)
- Virtual networking configuration (switches, subnets, IP addressing)
- Network connectivity between VMs
- Infrastructure requirements for your lab environment

The Definition Builder automates the creation of these scripts through an intuitive web interface.

## Step-by-Step Process

The New Definition page uses a 4-step wizard to guide you through lab creation:

### Step 1: Lab Information

Configure basic lab metadata:

- **Lab Name**: A descriptive name for your lab environment
  - Examples: "Active Directory Lab", "Exchange Environment", "Development Cluster"
  - Avoid special characters and keep names descriptive
- **Lab Description** _(Optional)_: Brief description of the lab's purpose and scope
  - Helps document the lab's intended use case
  - Useful for team environments and lab management

### Step 2: Virtual Switch Configuration

Define the network infrastructure for your lab environment.

#### Virtual Switch Types

##### Default Switch (Recommended for Internet Access)

- Provides NAT-based internet connectivity
- Automatically configured by Hyper-V
- Best for labs that need external internet access
- No additional configuration required

##### Internal Switch

- Creates isolated networks between VMs
- Requires manual IP configuration
- Best for secure, isolated environments
- Configuration options:
  - **Address Space**: CIDR notation (e.g., `192.168.1.0/24`)
  - **Gateway IP**: Optional gateway address (e.g., `192.168.1.1`)

##### External Switch

- Bridges VMs to physical network adapters
- Provides direct access to physical network
- Requires specifying physical adapter name
- Configuration options:
  - **Physical Adapter Name**: Network adapter to bridge (e.g., "Ethernet", "Wi-Fi")

#### Adding Virtual Switches

1. Enter a **Virtual Switch Name** (e.g., "Internal", "Management", "DMZ")
2. Select the **Switch Type** from the dropdown
3. Configure type-specific settings (if required)
4. Click **Add Virtual Switch**
5. Use **Add Default Switch** button for quick NAT setup

#### Switch Management

- View all configured switches in the summary table
- Remove switches using the **Remove** button
- Switch details show type, addressing, and configuration

**Requirements**: Define at least one virtual switch before proceeding to VM configuration.

### Step 3: Virtual Machine Configuration

Design and configure virtual machines for your lab environment.

#### VM Specifications

**Basic Configuration**:

- **VM Name**: Unique identifier for the virtual machine
  - Use descriptive names: "DC01", "WEB01", "CLIENT01"
  - Follow consistent naming conventions
- **VM Size**: Predefined resource templates
  - **Small**: 2 CPU cores, 4GB RAM
  - **Medium**: 4 CPU cores, 8GB RAM  
  - **Large**: 8 CPU cores, 16GB RAM
- **Operating System**: Select from available OS images
  - Automatically populated from `Get-LabAvailableOperatingSystem`
  - Includes Windows Server and client operating systems
  - Falls back to common options if detection fails

#### Network Interface Configuration

Each VM requires at least one network interface card (NIC) to connect to virtual switches.

**Adding Network Adapters**:

1. Select a **Virtual Switch** from configured switches
2. Choose **IP Assignment** method:
   - **DHCP (Automatic)**: Automatic IP configuration
   - **Static IP**: Manual IP configuration
3. For static IP configuration, specify:
   - **IP Address**: Static IP address for the interface
   - **Gateway**: Default gateway address
   - **DNS Server**: DNS server address
4. Click **Add NIC** to attach the adapter to the VM

**NIC Management**:

- Multiple NICs per VM supported for complex networking
- Interfaces automatically named (Ethernet1, Ethernet2, etc.)
- Remove NICs using the **Remove** button
- View NIC configuration in the summary table

#### Adding Virtual Machines

1. Configure VM specifications (name, size, OS)
2. Add at least one network adapter
3. Click **Add Virtual Machine**
4. VM appears in the summary table with full configuration

**VM Management**:

- View all configured VMs with specifications
- See network adapter assignments per VM
- Remove VMs using the **Remove** button
- Modify by removing and re-adding

### Step 4: Review and Generate

Review your complete lab configuration and generate the PowerShell definition script.

#### Lab Summary

The summary displays:

**Lab Information**:

- Lab name and description
- Count of virtual switches and VMs
- Total resource allocation (CPU cores, RAM)

**Resource Summary**:

- Combined CPU and memory requirements
- Network adapter assignments
- Infrastructure overview

#### Definition Generation

**Generate & Download Lab Definition**:

- Creates a complete AutomatedLab PowerShell script
- Downloads as `.ps1` file with timestamp
- Ready to use with AutomatedLab commands
- Includes all VM, network, and configuration details

**Preview Lab Definition**:

- Shows the generated PowerShell code
- Syntax-highlighted code editor
- Read-only preview for verification
- Allows review before download

**Start New Lab**:

- Clears all configuration data
- Resets wizard to step 1
- Begins fresh lab design process

## Generated Definition Structure

The Definition Builder creates PowerShell scripts with this structure:

```powershell
# Lab: [Your Lab Name]
# Description: [Your Description]
# Generated: [Timestamp]

# Initialize the lab
New-LabDefinition -Name '[Lab Name]' -DefaultVirtualizationEngine HyperV

# Add virtual switches
Add-LabVirtualNetworkDefinition -Name '[Switch Name]' -VirtualizationEngine HyperV

# Configure machines
Add-LabMachineDefinition -Name '[VM Name]' `
    -OperatingSystem '[OS Name]' `
    -Processors [CPU Count] `
    -Memory [RAM in GB]GB `
    -Network '[Network Name]'

# Install the lab
Install-Lab
```

## Best Practices

### Planning Your Lab

**Network Design**:

- Start with network requirements before VMs
- Use Default Switch for internet access needs
- Create Internal switches for secure communication
- Document IP addressing schemes

**VM Sizing**:

- Start with smaller VMs and scale up if needed
- Consider your host system's resource limitations
- Plan for concurrent VM operations
- Account for host OS resource requirements

**Naming Conventions**:

- Use consistent naming patterns
- Include role indicators (DC, WEB, SQL, CLIENT)
- Number similar VMs sequentially (WEB01, WEB02)
- Avoid special characters and spaces

### Resource Planning

**System Requirements**:

- Ensure adequate host RAM for all VMs
- Plan for concurrent VM operations
- Consider storage requirements for VM disks
- Account for network bandwidth needs

**Performance Optimization**:

- Don't over-provision resources initially
- Monitor resource usage during lab operation
- Scale resources based on actual usage patterns
- Consider using checkpoints for state management

## Integration with Lab Configurations

Once your definition is generated:

1. **Save the Definition File**: Store in a consistent location for reuse
2. **Create Lab Configuration**: Use the "New Lab" page to map the definition to a lab instance
3. **Manage the Lab**: Start, stop, and monitor through the "Manage Labs" page
4. **Customize Further**: Edit the generated script for advanced scenarios

## Troubleshooting

### Common Issues

#### "No Operating Systems Available"

- Verify AutomatedLab module is properly installed
- Check if `Get-LabAvailableOperatingSystem` command works
- Ensure ISO files or VM templates are available
- Falls back to default OS options automatically

#### "Please Define Virtual Switches First"

- Complete Step 2 before proceeding to VM configuration
- At least one virtual switch is required
- Use "Add Default Switch" for quick setup

#### "Please Add Network Adapters"

- Each VM requires at least one network interface
- Select a virtual switch before adding the VM
- Use DHCP for simple configurations

#### Resource Planning Issues

- Total VM resources exceed host capabilities
- Consider smaller VM sizes or fewer concurrent VMs
- Monitor host resource usage during operation

### Validation

The wizard validates:

- Unique VM and switch names
- Required network adapters for each VM
- Minimum configuration requirements
- Resource allocation conflicts

## Advanced Usage

### Manual Customization

Generated definitions can be manually edited for:

- Advanced networking configurations
- Custom software installations
- Domain controller setup
- Specialized role configurations
- PowerShell DSC integration

### Template Reuse

- Save successful definitions as templates
- Modify existing definitions for new scenarios
- Share definitions across teams
- Version control definition files

### Integration Points

- Use with AutomatedLab.Utils for advanced features
- Integrate with CI/CD pipelines for automated lab provisioning
- Combine with custom roles for specialized configurations
- Export/import lab configurations for portability

## Related Resources

- **Lab Configurations**: See [Configurations documentation](./Configurations.md) for mapping definitions to lab instances
- **Custom Roles**: See [Roles documentation](./Roles.md) for specialized machine configurations
- **AutomatedLab Documentation**: Official AutomatedLab project documentation
- **AutomatedLab.Utils**: [Extended utilities and features](https://github.com/steviecoaster/automatedlab.utils)
