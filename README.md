# AutomatedLab UI

AutomatedLab UI is  PowerShell Universal app that provides a web-based frontend for AutomatedLab management powered by AutomatedLab.Utils. _Technically_ you should consider this a frontend for AutomatedLab.Utils, but let's not split hairs.

TL;DR

Once you have an AutomatedLab script, you use this thing to manage the lab, and various other components of AutomatedLab as well

## Features

- **Lab Management**: Define new Lab configurations, Start/Stop labs under management
- **ISO Management**: Upload, view, and manage ISO files for lab deployments
- **Custom Roles**: Create and manage custom roles for lab machines

## Requirements

- [PowerShell Universal 5.0+](https://powershelluniversal.com)
- [AutomatedLab.Utils module (v1.6.0+)](https://github.com/steviecoaster/automatedlab.utils)
- Configuration module (v1.6.0+)
- Windows environment (for AutomatedLab functionality)
- PowerShell 7

## Installation

### From PowerShell Gallery

_Coming Soon_

~~You can install this module from the PowerShell Gallery directly inside PowerShell Universal. See [the PSU docs](https://docs.powershelluniversal.com/platform/modules#install-modules-from-the-gallery) for instructions.~~

### Manual Installation

***BEFORE YOU BEGIN***

_Ensure you have the necessary pre-requisites installed before continuing_

1. Clone this repository
2. Copy the `PowerShellUniversal.Apps.AutomatedLab` folder to `C:\ProgramData\UniversalAutomation\Repository\Modules` on your PSU server.
3. Restart PowerShell Universal
4. The app will be automatically deployed at `/automatedlab`

## Usage

Once installed, navigate to `/automatedlab` in your PowerShell Universal instance to access the app. The interface provides the following sections:

- **Home**: Overview and quick access to main features
- **Manage Labs**: View and manage existing lab environments. See [docs/Labs.md](docs/Labs.md)
- **New Lab Configuration**: Create new AutomatedLab environments. See [docs/Configurations.md](docs/Configurations.md)
- **Manage ISOs**: Upload and manage ISO files. See [docs/ISO.md](docs/ISO.md)
- **Custom Roles**: Create and configure custom machine roles. See [docs/Roles.md](docs/Roles.md)

## Configuration

This module requires the AutomatedLab.Utils and Configuration modules to be installed. These dependencies are automatically installed when you install this module.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Support

For issues related to this PowerShell Universal app, please create an issue in this GitHub repository. For AutomatedLab-specific questions, refer to the [AutomatedLab documentation](https://github.com/AutomatedLab/AutomatedLab).

For issues with AutomatedLab.Utils, please create an issue in the GitHub repository at [https://github.com/steviecoaster/automatedlab.utils](https://github.com/steviecoaster/automatedlab.utils)