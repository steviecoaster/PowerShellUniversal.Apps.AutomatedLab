# Managing Your Lab ISOs

Need to add operating systems to your AutomatedLab? The **Manage ISOs** page is where you'll upload and organize all your Windows and Linux installation files. Think of it as your OS library - once you add ISOs here, they'll be available when creating labs.

## What You Can Do Here

- **Add new ISOs** - Upload Windows Server, Windows 10/11, Linux distros, whatever you need
- **See what's already available** - Browse your current OS collection organized by family
- **Remove old ISOs** - Clean up space by deleting ISOs you don't need anymore
- **Check file sizes** - See how much disk space each ISO is using

## Adding Your First ISO

### Quick Steps

1. **Click the big green "Add New ISO" button** - you can't miss it
2. **Type the full path to your ISO file** - like `C:\ISOs\Windows11.iso` or `\\server\share\Ubuntu22.04.iso`
3. **Hit submit** - the system will scan your ISO and add all the OS versions it finds

That's it! Your new operating systems will immediately show up in the lab creation wizard.

### What File Paths Work?

✅ **Local files**: `C:\MyISOs\WindowsServer2022.iso`
✅ **Network shares**: `\\fileserver\isos\Windows11.iso` 
✅ **Mapped drives**: `Z:\ISOs\Ubuntu22.04.iso`

❌ **Won't work**: Anything that's not a `.iso` file or doesn't exist

## Browsing Your ISO Collection

Your ISOs are automatically organized into families to keep things tidy:

### Windows Families

- **Windows 11** - All your Windows 11 editions
- **Windows 10** - Pro, Enterprise, Home, etc.
- **Windows Server 2022** - Standard, Datacenter, Core
- **Windows Server 2019** - All server editions
- And so on...

### Linux Families  

- **Ubuntu** - Different versions and flavors
- **CentOS** - All CentOS releases
- **Red Hat Enterprise Linux** - RHEL variants

### What You'll See

Each family shows you:

- **How many OS editions** are in that ISO
- **Where the file is located** on your system
- **How big the file is** (helpful for managing disk space)

**Pro tip**: Click on any family row to expand it and see exactly which operating systems are available!

## Removing ISOs You Don't Need

Got ISOs eating up disk space? Here's how to clean them up:

### The Safe Way to Remove ISOs

1. **Find the family you want to remove** in the table
2. **Click "Remove ISO"** - don't worry, it won't delete anything yet
3. **Check the confirmation dialog** - it shows you exactly what will be removed
4. **Click "Remove All ISOs"** if you're sure, or "Cancel" if you changed your mind

**Important**: This actually deletes the ISO file from your disk, so make sure you have backups if you might need it later!

## When Things Go Wrong

### "ISO file does not exist"

**What happened**: The path you entered doesn't point to a real file  
**Fix it**: Double-check your file path and make sure the ISO actually exists there

### "No ISOs Found" 

**What happened**: You haven't added any ISOs yet  
**Fix it**: Click "Add New ISO" and upload your first one!

### "Error Loading ISOs"

**What happened**: Something's wrong with the AutomatedLab setup  
**Fix it**: Check that AutomatedLab is properly installed and configured

### Missing File Indicators

**What happened**: You moved or deleted an ISO file outside of this interface  
**Fix it**: Either put the file back where it was, or remove the broken entry and re-add it

## What Happens Next?

Once you've added ISOs here, they automatically become available in:

- **Lab Creation Wizard** - They'll show up in the operating system dropdown
- **Lab Configurations** - Available for any lab definitions you create
- **All lab tools** - Anything that needs an OS will see your ISOs

No restarts, no refreshing, no waiting - it just works!

## Need More Help?

- **Creating labs with your ISOs**: Check out the [Lab Creation Wizard guide](./Definitions.md)
- **Setting up lab configurations**: See the [Lab Configuration guide](./Configurations.md)  
- **AutomatedLab basics**: Visit the official AutomatedLab documentation
