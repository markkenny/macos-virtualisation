# INTRODUCTION
Virtualise macOS; So I saw a Rob Potvin Zoom presentation, Amsterdam or Belgium MacAdmins, about virtualisimg macOS on Apple Silicon and have been happy using UTM for a long while. And his recent [Baking Guide for virtualisation](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/) (great apron!) got me thinking; tart, packer, ansible and variable-isationinising. (My word!) 

The Tart and Packer and Robs guides are great, but use admin/admin as login and password and I want to use use my user/password to build my VMs. I went down a rabbit hole of learning with way too many evenings of watching 15 minute macOS installs, (my wife hearing the voiceover part), trying to get the run to work with Apples changes to the build order since Robs presentation! Also, current guides have commands that do admin to user admin! If the user was named FRANK or SUSAN I could see the admin command against the user! I hope this'll make that bit a little clearer. 

I've also sped up the wait commands as much as I could. My testing has been on a M1 MacBookPro, so let's assume as long as you're running on anything as modern, you'll be fine. I challenged myself to get it below 10 mins, and I did this lots!

Good luck folks. It's a good suite of tools, this is how I got 'em to work.

## TAHOE
Tahoe is now working for me. Some new windows and I'll tweak the waits in future.

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
**Remember to add .env to your .gitignore!**
A .env file is needed with the variables, username, password and JSS enrollment URL.
```PACKER_VAR_mac_username="XXXXX"
PACKER_VAR_mac_password="XXXXX"
PACKER_VAR_jamf_url="https://myjamf.jamfcloud.com"
PACKER_VAR_jamf_invitation_id="1234567890"
```
### IPSW
ipsw_url can be used to source the IPSW installer from a HTTPS link or path.

You can download IPSW or get the links from [MrMacintosh](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/)

### Settings
Variable "vm_name" will be the name for the folder saved in ~/.tart/vms/ (unless changing manually, this is WIP) Copy the .pkr.hcl file, change vm_name and test. 

Edit "tart-cli" "tart" for hardware settings and Mac is configured with the build using the shell provisioner. 

### Ansible for updates
Ansible is used to update the macOS during build, which needs Python which is installed with the Command Line Tools. If you are using and old IPSW for a specific macOS version, or you just don't want to update, remove these blocks.
Config "playbook-system-updater.yml" is set to admin, but this is overwritten with .env Adn again, not needed if you don't want to update.

## Build
The script Packer.sh will run a sanity check and list all packer files stored locally and build to ~/.tart/vms/ Process takes 10-15 minutes.

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


