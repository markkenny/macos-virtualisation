# INTRODUCTION
Virtualise macOS; So I saw a Rob Potvin Zoom presentation, Amsterdam or Belgium MacAdmins, about virtualisimg macOS on Apple Silicon and have been happy using UTM for a long while. And his recent [Baking Guide for virtualisation](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/) (great apron!) got me thinking; tart, packer, ansible and variable-isationinising. (My word!) 

![Apple Pie Mac Mini](/images/applepiemini.jpg)

The Tart and Packer and Robs guides are great, but use admin/admin as login and password and I want to use use my user/password to build my VMs. I went down a rabbit hole of learning with way too many evenings of watching 15 minute macOS installs, (my wife hearing the voiceover part), trying to get the run to work with Apples changes to the build order since Robs presentation! Also, current guides have commands that do admin to user admin! If the user was named FRANK or SUSAN I could see the admin command against the user! I hope this'll make that bit a little clearer. 

I've also sped up the wait commands as much as I could. My testing has been on a M1 MacBookPro, so let's assume as long as you're running on anything as modern, you'll be fine. I challenged myself to get it below 10 mins, and I did this lots!

Good luck folks. It's a good suite of tools, this is how I got 'em to work.

## TAHOE
Unless you're running Tahoe yourself, you do need Device Support Update from [developer.apple.com](https://developer.apple.com/download/) Manual PKG install.

# SETUP

## Install Tart and Packer
Homebrew required to install binaries; tart and packer.
```brew install cirruslabs/cli/tart
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

## Packer templates - Packs
If pulling from this my Git repo', they're kept in the Packs folder, and I'll update there. Just vanilla builds of clean macOS. This is relevant for my Packer and Tarter scripts.

### Credentials
A PACKNAME_ENV_TEMPLATE.pkr.hcl.env file is needed with these and other variables to be able to pack; username, password and JSS enrollment URL. 
**Remember to add *.env.hcl to your .gitignore!**

```
# VM Configuration
vm_name  = "vanilla-26.1"
ipsw_url = "https://updates.cdn-apple.com/2025FallFCS/fullrestores/089-04148/791B6F00-A30B-4EB0-B2E3-257167F7715B/UniversalMac_26.1_25B78_Restore.ipsw"

# Account Configuration
account_userName = "admin"
account_password = "admin"

# MDM Enrollment Configuration
enrollment_type    = "profile"
jamf_url           = "https://SERVER.jamf.com"
mdm_invitation_id  = "1234567890"

# Feature Toggles
enable_passwordless_sudo   = "false"
enable_auto_login          = "false"
enable_safari_automation   = "false"
enable_screenlock_disable  = "false"
enable_spotlight_disable   = "false"
enable_clipboard_sharing   = "false"
```

### Credentials - OLD - Pre December 2026
A .env file is needed with these variables to be able to pack; username, password and JSS enrollment URL. **Remember to add .env to your .gitignore!**
```
PACKER_VAR_mac_username="admin"
PACKER_VAR_mac_password="admin"
PACKER_VAR_jamf_invitation_id="PICK ONE"
PACKER_VAR_jamf_url="https://client.jamf.com"
PACKER_VAR_devjamf_url="https://dev.jamf.com"
PACKER_VAR_devjamf_invitation_id="PICK ONE"
```

### IPSW
ipsw_url can be used to source the IPSW installer from a HTTPS link or path.

You can download IPSW or get the links from [MrMacintosh](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/)

### Settings
Variable "vm_name" will be the name for the folder saved in ~/.tart/vms/ (unless changing manually, this is WIP) Copy the .pkr.hcl file, change vm_name and test. 

Edit "tart-cli" "tart" for hardware settings and Mac is configured with the build using the shell provisioner. 

### Ansible for updates
Ansible can used to update the macOS during build, which needs Python which is installed with the Command Line Tools. If you are using and old IPSW for a specific macOS version, or you just don't want to update, remove these blocks.
Config "playbook-system-updater.yml" is set to admin, but this is overwritten with .env Adn again, not needed if you don't want to update.

## Build
The script Packer.sh will run a sanity check and list all packer files stored locally and build to ~/.tart/vms/ Process takes 15-20 minutes.

While running, do not interact with the tart window!! Don't click in there! Let it run!

## Tart
Once you've 'packer'd a packs, tart clones and runs the VMs.

Simply...
```MASTER="vanilla-sequoia.pkr.hcl"
CLONE="MyTest"
tart clone $MASTER $CLONE
tart set $CLONE$ --display-refit --random-serial --random-mac
tart run $CLONE
```

A cloned VM will run as long as the command is running. Quit the VM or kill the command.

### Tarter.sh
A simple script to list any installed VMs and offer to clone, set a random serial and MAC, or run them. Local user folder is mounted in /Volumes/My Shared Files/Home
It runs the tart with nohup VM boots so the script stops and tart keeps the VM running.

Once the VM is running, you can see which ones are with `tart list`

### Public Images
Great if you want a built VM with admin/admin 
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest sequoia-base
tart run sequoia-base

# LINKS
## Where I started learning
[Robs Guide](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/)
[YouTube](https://www.youtube.com/watch?v=7DqS9bG3bkg)
[Rob Potvin example apple-tart-enrollment-url.pkr.hcl](https://github.com/motionbug/macad.uk2025/tree/main/packer-templates)
## Tart guides
Tart stores all its files in ~/.tart/ directory. Local images that you can run are stored in ~/.tart/vms/. Remote images are pulled into ~/.tart/cache/OCIs/.
[Tart Quick Start](https://tart.run/quick-start/) [Tart VM Management](https://tart.run/integrations/vm-management/) [Cirrus Labs](https://github.com/cirruslabs/tart) [Cirrus Labs README](https://github.com/cirruslabs/tart/blob/main/README.md)
## IPSWs
[MrMacintosh for the win!](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/)
## Packer and UTM
https://github.com/naveenrajm7/packer-plugin-utm?tab=readme-ov-file
https://github.com/naveenrajm7/packer-plugin-utm/blob/main/docs/post-processors/zip.mdx


