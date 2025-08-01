# Lab Management

The Lab Management feature provides comprehensive control over your AutomatedLab environments through a web interface.

## Overview

The Lab Management page allows you to:
- View all available lab configurations
- Start and stop lab environments
- Monitor lab status and details
- Access detailed lab information and parameters

## Features

### Lab Discovery

- Automatically discovers lab configurations in your system
- Displays lab definitions from the AutomatedLab.Utils module

### Lab Control

- **Start Labs**: Deploy and start lab environments with a single click
- **Stop Labs**: Safely shutdown and deallocate lab resources
- ~~**Status Monitoring**: Real-time status updates for lab environments~~ - _Future Release_

### Lab Information

- **Basic Information**: Lab name, definition file, and description
- ~~**Lab Parameters**: Detailed configuration parameters for each lab~~ - _Future release_
- ~~**Resource Details**: Information about allocated resources and components~~ - Future release

## Using Lab Management

### Viewing Available Labs

1. Navigate to the "Manage Labs" page from the main menu
2. The interface will display all discovered lab configurations
3. Click on the Details button to view detailed information about a particular lab

### Starting a Lab

1. Select the lab you want to start from the list
2. Click the "Start Lab" button
3. The lab will be deployed and made available

### Stopping a Lab

1. Locate the running lab in the list
2. Click the "Stop Lab" button
3. Confirm the shutdown operation
4. Resources will be safely deallocated

### Viewing Lab Details

1. Click on a lab name to expand the details view
2. Review basic information including:
   - Lab name and definition file
   - Configuration parameters
   - Resource allocation details
3. Use this information to understand lab composition before deployment

## Troubleshooting

### Common Issues

- **Lab Not Appearing**: Ensure lab definition files are in the correct location
- **Start Failures**: Check system resources and Hyper-V configuration
- **Slow Operations**: Lab deployment can take time depending on configuration

### Error Resolution

- Check AutomatedLab logs for detailed error information
- Verify Hyper-V is properly configured and running
- Ensure sufficient disk space and memory for lab deployment
- Review lab definition files for syntax errors
