packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "vm_name" {
  type        = string
  default     = "macOS-vanilla-15.6.1-NO-UPDATE"
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
  default     = "https://updates.cdn-apple.com/2025SummerFCS/fullrestores/093-10809/CFD6DD38-DAF0-40DA-854F-31AAD1294C6F/UniversalMac_15.6.1_24G90_Restore.ipsw"
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
    "<wait4s><tab><tab>UTC<enter><leftShiftOn><tab><tab><leftShiftOff><wait2s><spacebar>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    "<wait2s><tab><wait4s><spacebar>",
    "<wait2s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    "<wait2s><tab><wait4s><spacebar>",
    "<wait8s><spacebar>",
    "<leftAltOn><f5><leftAltOff>",
    # Terminal settings
    "<wait6s><leftAltOn><spacebar><leftAltOff>Terminal<wait2s><enter>",
    "<wait2s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # System Settings
    "<wait2s><leftAltOn><spacebar><leftAltOff>System Settings<wait2s><enter>",
    "<wait2s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<enter>",
    "<wait2s><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait2s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # Terminal settings
    "<wait4s><leftAltOn><spacebar><leftAltOff>Terminal<wait2s><enter>",
    "<wait2s>sudo spctl --global-disable<enter>",
    "<wait2s>${var.mac_password}<wait2s><enter>",
    "<wait2s><leftAltOn>q<leftAltOff>",
    # System Settings
    "<wait2s><leftAltOn><spacebar><leftAltOff>System Settings<wait2s><enter>",
    "<wait2s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<wait2s><enter>",
    "<wait2s><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff>",
    "<wait2s><down><wait1s><down><wait1s><enter>",
    "<wait2s>${var.mac_password}<wait2s><enter>",
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

}