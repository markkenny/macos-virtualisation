packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "jamf_invitation_id" {
  type        = string
  default     = "invitationidhere"
  description = "MDM enrollment invitation ID"
}

variable "jamf_url" {
  type        = string
  default     = "https://instance.jamfcloud.com"
  description = "Jamf Cloud URL"
}

locals {
  uuid = uuidv4()
}

variable "vm_name" {
  type        = string
  default     = "macOS-vanilla-26.0-MDM"
  description = "Name of the virtual machine to create"
}

variable "ipsw_url" {
  type        = string
  # MUST BE A TAHOE IMAGE - either URL or path to IPSW
  default     = "/Users/mark.kenny/zMEDIA/INSTALLERS_OS/UniversalMac_26.0_25A5349a_Restore.ipsw"
  description = "URL to the macOS IPSW file"
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

source "tart-cli" "tart" {
  from_ipsw    = var.ipsw_url
  vm_name      = var.vm_name
   cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 64
  ssh_username = var.mac_username
  ssh_password = var.mac_password
  ssh_timeout  = "180s"
  boot_command = [
    # hello, hola, bonjour, etc.
    "<wait32s><spacebar>",
    # Language: most of the times we have a list of "English"[1], "English (UK)", etc. with
    # "English" language already selected. If we type "english", it'll cause us to switch
    # to the "English (UK)", which is not what we want. To solve this, we switch to some other
    # language first, e.g. "Italiano" and then switch back to "English". We'll then jump to the
    # first entry in a list of "english"-prefixed items, which will be "English".
    #
    # [1]: should be named "English (US)", but oh well 🤷
    "<wait20s>italiano<esc>english<enter>",
    # Select Your Country or Region
    "<wait28s>united states<leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Transfer Your Data to This Mac
    "<wait6s><tab><tab><tab><spacebar><tab><tab><wait2s><spacebar>",
    # Written and Spoken Languages
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Accessibility
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Data & Privacy
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Create a Mac Account
    "<wait6s><tab><tab><tab><tab><tab><tab>${var.mac_username}<tab>${var.mac_username}<tab>${var.mac_password}<tab>${var.mac_password}<tab><tab><spacebar><tab><tab><wait2s><spacebar>",
    # Enable Voice Over
    "<wait60s><leftAltOn><f5><leftAltOff>",
    # Sign In with Your Apple ID
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Are you sure you want to skip signing in with an Apple ID?
    "<wait6s><tab><spacebar>",
    # Terms and Conditions
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # I have read and agree to the macOS Software License Agreement
    "<wait6s><tab><wait2s><spacebar>",
    # Enable Location Services
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Are you sure you don't want to use Location Services?
    "<wait6s><tab><wait2s><spacebar>",
    # Select Your Time Zone
    "<wait6s><tab><tab><tab>UTC<enter><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Analytics
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Screen Time
    "<wait6s><tab><tab><wait2s><spacebar>",
    # Siri
    "<wait6s><tab><spacebar><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # You Mac is Ready for FileVault
    "<wait6s><leftShiftOn><tab><tab><leftShiftOff><spacebar>",
    # Mac Data Will Not Be Securely Encrypted
    "<wait6s><tab><spacebar>",
    # Choose Your Look
    "<wait6s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Update Mac Automatically
    "<wait6s><tab><tab><spacebar>",
    # Welcome to Mac
    "<wait10s><spacebar>",
    # Disable Voice Over
    "<wait6s><leftAltOn><f5><leftAltOff>",
    # Enable Keyboard navigation
    # This is so that we can navigate the System Settings app using the keyboard
    "<wait6s><leftAltOn><spacebar><leftAltOff>Terminal<wait6s><enter>",
    "<wait10s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<wait2s><enter>",
    "<wait6s><leftAltOn>q<leftAltOff>",
    # Now that the installation is done, open "System Settings"
    "<wait6s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    # Navigate to "Sharing"
    "<wait6s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<enter>",
    # Navigate to "Screen Sharing" and enable it
    "<wait6s><tab><tab><tab><tab><tab><spacebar>",
    # Navigate to "Remote Login" and enable it
    "<wait6s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait2s><spacebar>",
    # Quit System Settings
    "<wait6s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper (1/2)
    "<wait6s><leftAltOn><spacebar><leftAltOff>Terminal<wait2s><enter>",
    "<wait6s>sudo spctl --global-disable<wait2s><enter>",
    "<wait6s>${var.mac_password}<wait2s><enter>",
    "<wait6s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper (2/2)
    "<wait6s><leftAltOn><spacebar><leftAltOff>System Settings<wait2s><enter>",
    "<wait6s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<wait2s><enter>",
    "<wait6s><leftShiftOn><tab><tab><tab><tab><tab><leftShiftOff>",
    "<wait6s><down><wait1s><down><wait1s><enter>",
    "<wait6s>${var.mac_password}<wait2s><enter>",
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
    # Quit System Settings
    "<wait6s><leftAltOn>q<leftAltOff>",
  ]

  // A (hopefully) temporary workaround for Virtualization.Framework's
  // installation process not fully finishing in a timely manner
  create_grace_time = "30s"

  // Keep the recovery partition, otherwise it's not possible to "softwareupdate"
  recovery_partition = "keep"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      // Enable passwordless sudo
      # "echo admin | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo 'admin ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/admin-nopasswd\"",
      "echo '${var.mac_password}' | sudo -S mkdir -p /etc/sudoers.d/",
      "echo '${var.mac_username} ALL=(ALL) NOPASSWD: ALL' | sudo -S tee /etc/sudoers.d/${var.mac_username}-nopasswd > /dev/null",
      "echo '${var.mac_password}' | sudo -S chmod 0440 /etc/sudoers.d/${var.mac_username}-nopasswd",
      // Enable auto-login
      //
      // See https://github.com/xfreebird/kcpassword for details.
      "echo '00000000: 1ced 3f4a bcbc ba2c caca 4e82' | sudo xxd -r - /etc/kcpassword",
      "sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser ${var.mac_username}",
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
      "sleep 30",
      "kill -9 $SAFARI_PID",
      // Enable Safari's remote automation
      "sudo safaridriver --enable",
      // Disable screen lock
      //
      // Note that this only works if the user is logged-in,
      // i.e. not on login screen.
      # "sysadminctl -screenLock off -password admin",
      "sysadminctl -screenLock off -password '${var.mac_password}' || true",
    ]
  }

  provisioner "shell" {
    inline = [
      # Ensure that Gatekeeper is disabled
      "spctl --status | grep -q 'assessments disabled'"
    ]
  }

  provisioner "shell" {
    inline = [
      # Install command-line tools
      "touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "softwareupdate --list | sed -n 's/.*Label: \\(Command Line Tools .*\\)/\\1/p' | tr '\\n' '\\0' | xargs -0 -I {} softwareupdate --install '{}'",
      "rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
    ]
  }
  
  provisioner "shell" {
    inline = [
      // Create MDM enrollment profile
      "cat << EOF > ~/Desktop/mdm_enroll.mobileconfig",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
      "<plist version=\"1.0\">",
      "    <dict>",
      "        <key>PayloadUUID</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadOrganization</key>",
      "        <string>JAMF Software</string>",
      "        <key>PayloadVersion</key>",
      "        <integer>1</integer>",
      "        <key>PayloadIdentifier</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadDescription</key>",
      "        <string>MDM Profile for mobile device management</string>",
      "        <key>PayloadType</key>",
      "        <string>Profile Service</string>",
      "        <key>PayloadDisplayName</key>",
      "        <string>MDM Profile</string>",
      "        <key>PayloadContent</key>",
      "        <dict>",
      "            <key>Challenge</key>",
      "            <string>${var.jamf_invitation_id}</string>",
      "            <key>URL</key>",
      "            <string>${var.jamf_url}/enroll/profile</string>",
      "            <key>DeviceAttributes</key>",
      "            <array>",
      "                <string>UDID</string>",
      "                <string>PRODUCT</string>",
      "                <string>SERIAL</string>",
      "                <string>VERSION</string>",
      "                <string>DEVICE_NAME</string>",
      "                <string>COMPROMISED</string>",
      "            </array>",
      "        </dict>",
      "    </dict>",
      "</plist>",
      "EOF"
    ]
  }
}

