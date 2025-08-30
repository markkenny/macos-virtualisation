packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "vm_name" {
  type        = string
  default     = "macOS-vanilla-15.5"
  description = "Name of the virtual machine to create"
}

variable "mac_username" {
  type        = string
  default     = "default-user"
  description = "Username for the default Mac account"
}

variable "mac_password" {
  type        = string
  default     = "secret-password"
  description = "Password for the default Mac account"
  sensitive   = true
}

variable "jamf_url" {
  type        = string
  default     = "https://myjamf.jamfcloud.com"
  description = "Jamf Cloud URL"
}

variable "jamf_invitation_id" {
  type        = string
  default     = "1234567890"
  description = "Invitation ID"
}

variable "ipsw_url" {
  type        = string
  default     = "https://updates.cdn-apple.com/2025SpringFCS/fullrestores/082-44534/CE6C1054-99A3-4F67-A823-3EE9E6510CDE/UniversalMac_15.5_24F74_Restore.ipsw"
  description = "URL to the macOS IPSW file"
}

source "tart-cli" "tart" {
  from_ipsw    = var.ipsw_url
  vm_name      = var.vm_name
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 64
  ssh_username = var.mac_username
  ssh_password = var.mac_password
  ssh_timeout  = "240s"
  boot_command = [
    "<wait32s><spacebar>",
    "<wait10s>italiano<esc>english<wait2s><enter>",
    "<wait10s>united states<leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait6s><tab><tab><tab><spacebar><tab><tab><wait2s><spacebar>",
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Account creation using variables
    "<wait4s>${var.mac_username}<tab>${var.mac_username}<tab>${var.mac_password}<tab>${var.mac_password}<tab><tab><wait2s><spacebar><tab><tab><wait2s><spacebar>",
    "<wait28s><leftAltOn><f5><leftAltOff>",
    # Enable Voiceover
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait4s><tab><wait2s><spacebar>",
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait4s><tab><wait2s><spacebar>",
    "<wait4s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait4s><tab><wait2s><spacebar>",
    # Set timezone
    "<wait2s><tab><tab>UTC<enter><leftShiftOn><tab><tab><leftShiftOff><wait2s><spacebar>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    "<wait2s><tab><wait4s><spacebar>",
    "<wait2s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    "<wait2s><tab><wait4s><spacebar>",
    "<wait8s><spacebar>",
    "<leftAltOn><f5><leftAltOff>",
    # Terminal settings
    "<wait2s><leftAltOn><spacebar><leftAltOff>Terminal<enter>",
    "<wait2s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # System Settings
    "<wait2s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    "<wait2s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<enter>",
    "<wait2s><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait2s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # Terminal settings
    "<wait4s><leftAltOn><spacebar><leftAltOff>Terminal<enter>",
    "<wait2s>sudo spctl --global-disable<enter>",
    "<wait2s>${var.mac_password}<enter>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # System Settings
    "<wait2s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    "<wait2s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<enter>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff>",
    "<wait2s><down><wait1s><down><wait1s><enter>",
    "<wait2s>${var.mac_password}<enter>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
    "<wait2s><leftAltOn>q<leftAltOff>",
  ]
  create_grace_time = "30s"
  recovery_partition = "keep"
}

build {
  sources = ["source.tart-cli.tart"]
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      // Create a webloc file on the desktop for Jamf Pro enrollment
      "cat << EOF > ~/Desktop/Enroll_OneJAMF.webloc",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<plist version=\"1.0\">",
      "<dict>",
      "    <key>URL</key>",
      "    <string>${var.jamf_url}/enroll?invitation=${var.jamf_invitation_id}</string>",
      "</dict>",
      "</plist>",
      "EOF",
      // Sudo shit
      "echo '${var.mac_password}' | sudo -S mkdir -p /etc/sudoers.d/",
      "echo '${var.mac_username} ALL=(ALL) NOPASSWD: ALL' | sudo -S tee /etc/sudoers.d/${var.mac_username}-nopasswd > /dev/null",
      "echo '${var.mac_password}' | sudo -S chmod 0440 /etc/sudoers.d/${var.mac_username}-nopasswd",
      // Disable screensaver at login screen
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      // Disable screensaver for admin user
      "defaults -currentHost write com.apple.screensaver idleTime 0",
      // Prevent the VM from sleeping
      "sudo systemsetup -setsleep Off 2>/dev/null",
      // Launch Safari to populate the defaults
      "/Applications/Safari.app/Contents/MacOS/Safari &",
      "SAFARI_PID=$!",
      "disown",
      "sleep 10",
      "kill -9 $SAFARI_PID",
      // Enable Safari's remote automation
      "sudo safaridriver --enable",
      // Disable screen lock
      //
      // Note that this only works if the user is logged-in,
      // i.e. not on login screen.
      "sysadminctl -screenLock off -password '${var.mac_password}' || true",
    ]
  }

  provisioner "shell" {
    inline = [
      # Install command-line tools needed for Ansible
      "touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "softwareupdate --list | sed -n 's/.*Label: \\(Command Line Tools for Xcode-.*\\)/\\1/p' | xargs -I {} softwareupdate --install '{}'",
      "rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
    ]
  }

  provisioner "ansible" {
    playbook_file = "ansible/playbook-system-updater.yml"
    extra_arguments = [
      "-vvv",
      "--extra-vars",
      "ansible_user=${var.mac_username}",
      "ansible_password=${var.mac_password}",
    ]
    ansible_env_vars = [
      "ANSIBLE_TRANSPORT=paramiko",
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
    use_proxy = false
  }

}