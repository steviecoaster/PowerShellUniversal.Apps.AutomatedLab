# Creating Custom Roles for Your Labs

Want to build VMs that do specific things? Custom roles let you create reusable "recipes" for VMs with pre-installed software, configurations, or special setups. Think of them as templates - build once, use everywhere!

## What Are Custom Roles?

Custom roles are basically folders with PowerShell scripts that automatically run when a VM boots up. Perfect for:

- **Installing software** like IIS, SQL Server, or development tools
- **Configuring Windows features** like Active Directory, DNS, or DHCP
- **Setting up applications** with your specific settings
- **Creating specialized servers** that your labs always need

## How to Create a New Role

### The Easy Way

1. **Click "Add Custom Role"** - opens up the creation form
2. **Give it a name** like "WebServer" or "DomainController" (something you'll remember)
3. **Choose your initialization script**:
   - **File**: Point to a `.ps1` script on your computer
   - **URL**: Link to a script on GitHub, a web server, wherever
4. **Add extra files** (optional) - any files your script needs to work
5. **Hit "Create Role"** and you're done!

### What's an Initialization Script?

This is the PowerShell script that runs when your VM starts up. It can do anything you want:

```powershell
# Example: Simple web server role
Install-WindowsFeature -Name IIS-WebServer
Install-WindowsFeature -Name IIS-ManagementConsole
New-Website -Name "MyApp" -Port 80 -PhysicalPath "C:\inetpub\wwwroot"
```

### Adding Extra Files

Got configuration files, installers, or other stuff your script needs? Add them in the "Additional Files" section:

- **Type the full path** to any file you want included
- **Click "Add File"** to add it to the list
- **Remove files** if you change your mind
- These files get copied to the VM automatically

**Examples of useful files**:

- Configuration files (web.config, app.config)
- Software installers (.msi, .exe files)
- Scripts that your main script calls
- Certificate files, license files, whatever you need

## Managing Your Existing Roles

### What You'll See

Your custom roles show up in a nice table with:

- **Role Name** - what you called it
- **Init Script** - shows if you have a working script (green) or if it's missing (red)
- **Files Count** - how many files are included
- **Created Date** - when you made it

### Getting Role Details

**Click "Details"** on any role to see:

- Full file path where it's stored
- Complete list of all files in the role
- Creation and modification dates

### Removing Roles You Don't Need

**Click "Remove"** and you'll get a confirmation dialog (because this really deletes the whole folder). Click "Remove Role" if you're sure, or "Cancel" if you changed your mind.

**Warning**: This actually deletes the files from your computer, so make sure you have backups if you might need them later!

## Where Are Roles Stored?

Your custom roles live in `C:\LabSources\CustomRoles\` with each role getting its own folder. Each folder should have:

- **Your main script** (usually named the same as your role)
- **Any additional files** you added

## Common Role Ideas

### Web Server Role

```powershell
# Install IIS and common features
Install-WindowsFeature -Name IIS-WebServer, IIS-ManagementConsole
Install-WindowsFeature -Name IIS-HttpRedirect, IIS-ASPNET45
```

### Development Machine Role

```powershell
# Install Chocolatey
Invoke-RestMethod https://ch0.co/go | Invoke-Expression
# Install development tools
choco install git vscode notepadplusplus -y
# Configure Windows features
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

## When Things Go Wrong

### "CustomRoles Directory Not Found"

**What happened**: The `C:\LabSources\CustomRoles\` folder doesn't exist  
**Fix it**: Create the folder manually, or let AutomatedLab create it for you

### "Missing" Init Script

**What happened**: Your script file moved or got deleted  
**Fix it**: Put the script back where it belongs, or remove and recreate the role

### Script Errors During VM Creation

**What happened**: Your PowerShell script has bugs or missing dependencies  
**Fix it**: Test your script on a regular VM first before using it in a role

## Pro Tips

### Writing Good Role Scripts

- **Test scripts first** on a regular VM before making them into roles
- **Use error handling** - wrap risky commands in try/catch blocks
- **Make scripts idempotent** - safe to run multiple times
- **Document what the script does** with comments

### Organizing Your Roles

- **Use clear names** like "SQLServer" not "MyScript"  
- **Group related files** in the same role folder
- **Version your scripts** if you're making lots of changes
- **Share successful roles** with your team

### File Management

- **Keep role scripts simple** - don't try to do everything in one script
- **Use additional files** for configuration files rather than hardcoding values
- **Test file paths** before adding them to roles
- **Back up your good roles** in case you accidentally delete them

## Using Roles in Your Labs

Once you create a role, it becomes available in:

- **Lab Configurations** - reference roles in your lab definition scripts
- **Manual lab scripts** - use `Add-LabMachineDefinition -Roles YourRoleName`

Your roles will automatically be applied when VMs boot up for the first time!

## Need More Help?

- **Building labs with roles**: Check out the [Lab Creation Wizard guide](./Definitions.md)
- **Setting up lab configurations**: See the [Lab Configuration guide](./Configurations.md)
- **AutomatedLab role concepts**: Visit the official AutomatedLab documentation
