packer {
  required_plugins {
    tart = {
      version = ">= 1.15.3"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# NOTES
# 2026 03 004 WIP - New window for Filevault needs to be skipped

# SOURCE
# https://github.com/motionbug/macad.uk2025/blob/main/packer-templates/apple-tart-tahoe.pkr.hcl

# VM Configuration
variable "vm_name" {
  type        = string
  default     = "this_is_the_base_image_name"
  description = "Name of the virtual machine to create"
}

variable "ipsw_url" {
  type        = string
  default     = "/path/to/macos.ipsw"
  description = "URL or path to the macOS TAHOE IPSW file"
}

# Account Configuration
variable "account_userName" {
  type        = string
  default     = "admin"
  description = "Username for the macOS account"
}

variable "account_password" {
  type        = string
  default     = "admin"
  description = "Password for the macOS account"
}

# MDM Enrollment Configuration
variable "enrollment_type" {
  type        = string
  default     = "profile"
  description = "Enrollment type (profile or link)"
}

variable "jamf_url" {
  type        = string
  default     = "https://instance.jamfcloud.com"
  description = "Jamf Cloud URL"
}

variable "mdm_invitation_id" {
  type        = string
  default     = "invitationidhere"
  description = "MDM enrollment invitation ID"
}

# MDM Enrollment Configuration DEV
variable "enrollment_type_dev" {
  type        = string
  default     = "profile"
  description = "Enrollment type (profile or link)"
}

variable "jamf_url_dev" {
  type        = string
  default     = "https://instance.jamfcloud.com"
  description = "Jamf Cloud URL"
}

variable "mdm_invitation_id_dev" {
  type        = string
  default     = "invitationidhere"
  description = "MDM enrollment invitation ID"
}

# Feature Toggles
variable "enable_passwordless_sudo" {
  type        = string
  default     = "true"
  description = "Enable passwordless sudo for the account"
}

variable "enable_auto_login" {
  type        = string
  default     = "true"
  description = "Enable automatic login for the account"
}

variable "enable_safari_automation" {
  type        = string
  default     = "true"
  description = "Enable Safari automation support"
}

variable "enable_screenlock_disable" {
  type        = string
  default     = "true"
  description = "Disable screen lock"
}

variable "enable_spotlight_disable" {
  type        = string
  default     = "true"
  description = "Disable Spotlight indexing"
}

variable "enable_clipboard_sharing" {
  type        = string
  default     = "false"
  description = "Enable clipboard sharing via tart guest agent"
}

# Locals
locals {
  uuid = uuidv4()
}

# -------------------------
# Source Definition
# -------------------------

source "tart-cli" "tart" {
  from_ipsw    = var.ipsw_url
  vm_name      = var.vm_name
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 120
  ssh_username = "${var.account_userName}"
  ssh_password = "${var.account_password}"
  ssh_timeout  = "60s"
  boot_command = [
    # hello, hola, bonjour, etc.
    "<wait60s><spacebar>",
    # Language: most of the times we have a list of "English"[1], "English (UK)", etc. with
    # "English" language already selected. If we type "english", it'll cause us to switch
    # to the "English (UK)", which is not what we want. To solve this, we switch to some other
    # language first, e.g. "Italiano" and then switch back to "English". We'll then jump to the
    # first entry in a list of "english"-prefixed items, which will be "English".
    #
    # [1]: should be named "English (US)", but oh well 🤷
    "<wait23s>italiano<esc>english<wait2s><enter>",
    # Select Your Country or Region
    "<wait23s><click 'Select Your Country or Region'><wait5s>united states<leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Transfer Your Data to This Mac
    "<wait6s><tab><tab><tab><spacebar><tab><tab><wait2s><spacebar>",
    # Written and Spoken Languages
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Accessibility
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Data & Privacy
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Create a Mac Account
    "<wait5s><tab><tab><tab><tab><tab><tab><wait2s>${var.account_userName}<tab><wait2s>${var.account_userName}<tab><wait2s>${var.account_password}<tab><wait2s>${var.account_password}<tab><tab><spacebar><tab><tab><wait2s><spacebar>",
    # Enable Voice Over
    "<wait73s><leftAltOn><f5><leftAltOff>",
    # Sign In with Your Apple ID
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Are you sure you want to skip signing in with an Apple ID?
    "<wait6s><tab><wait2s><spacebar>",
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
    "<wait6s><leftShiftOn><tab><tab><leftShiftOff><wait2s><spacebar>",
    # Mac Data Will Not Be Securely Encrypted
    "<wait6s><tab><wait2s><spacebar>",
    # Choose Your Look
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Update Mac Automatically
    "<wait6s><tab><tab><wait2s><spacebar>",
    # Welcome to Mac
    "<wait23s><spacebar>",
    # Disable Voice Over
    "<wait6s><leftAltOn><f5><leftAltOff>",
    # Enable Keyboard navigation
    # This is so that we can navigate the System Settings app using the keyboard
    "<wait6s><leftAltOn><spacebar><leftAltOff>Terminal<wait6s><enter>",
    "<wait6s><wait6s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    # Now that the installation is done, open "System Settings"
    # On Tahoe opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait6s>open '/System/Applications/System Settings.app'<wait2s><enter>",
    # Navigate to "Sharing"
    "<wait6s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<wait2s><enter>",
    # Navigate to "Screen Sharing" and enable it
    "<wait6s><tab><tab><tab><tab><tab><wait2s><spacebar>",
    # Navigate to "Remote Login" and enable it
    "<wait6s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><wait2s><spacebar>",
    # Quit System Settings
    "<wait6s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper (1/2)
    "<wait6s>sudo spctl --global-disable<enter>",
    "<wait5s>${var.account_password}<wait2s><enter>",
    # Disable Gatekeeper (2/2)
    # On Tahoe opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait6s>open '/System/Applications/System Settings.app'<enter>",
    "<wait6s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<wait2s><enter>",
    "<wait6s><leftShiftOn><tab><tab><tab><tab><tab><tab><leftShiftOff>",
    "<wait6s><down><wait2s><down><wait2s><enter>",
    "<wait5s>${var.account_password}<wait2s><enter>",
    "<wait6s><leftShiftOn><tab><leftShiftOff><wait2s><spacebar>",
    # Quit System Settings
    "<wait6s><leftAltOn>q<leftAltOff>",
  ]

  run_extra_args = [
    "--no-audio"
  ]

  create_grace_time  = "23s"
  recovery_partition = "keep"
}

# -------------------------
# Build Section
# -------------------------
build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "if [ \"${var.enrollment_type}\" = \"profile\" ]; then",
      "  cat << 'EOF' > ~/Desktop/OneJAMF_MDM_Enroll.mobileconfig",
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
      "            <string>${var.mdm_invitation_id}</string>",
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
      "EOF",
      "elif [ \"${var.enrollment_type}\" = \"link\" ]; then",
      "cat << 'EOF' > ~/Desktop/OneJAMF_Enroll.webloc",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<plist version=\"1.0\">",
      "<dict>",
      "    <key>URL</key>",
      "    <string>${var.jamf_url}/enroll?invitation=${var.mdm_invitation_id}</string>",
      "</dict>",
      "</plist>",
      "EOF",
      "fi",
    ]
  }

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "if [ \"${var.enrollment_type_dev}\" = \"profile\" ]; then",
      "  cat << 'EOF' > ~/Desktop/DEV_MDM_Enroll.mobileconfig",
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
      "            <string>${var.mdm_invitation_id_dev}</string>",
      "            <key>URL</key>",
      "            <string>${var.jamf_url_dev}/enroll/profile</string>",
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
      "EOF",
      "elif [ \"${var.enrollment_type}\" = \"link\" ]; then",
      "cat << 'EOF' > ~/Desktop/DEV_Enroll.webloc",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<plist version=\"1.0\">",
      "<dict>",
      "    <key>URL</key>",
      "    <string>${var.jamf_url_dev}/enroll?invitation=${var.mdm_invitation_id_dev}</string>",
      "</dict>",
      "</plist>",
      "EOF",
      "fi",
    ]
  }

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",

      # Passwordless sudo
      "if [ \"${var.enable_passwordless_sudo}\" = \"true\" ]; then",
      "  echo \"Enabling passwordless sudo for ${var.account_userName}...\"",
      "  echo ${var.account_password} | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo '${var.account_userName} ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/${var.account_userName}-nopasswd\"",
      "fi",

      # Auto-login
      "if [ \"${var.enable_auto_login}\" = \"true\" ]; then",
      "   curl https://raw.githubusercontent.com/karthikeyan-mac/Virtualization_macOS/refs/heads/main/kcpasswordgen.sh -o /tmp/kcpasswordgen.sh",
      "   encoded_value=\"$(bash /tmp/kcpasswordgen.sh ${var.account_password})\"",
      "   echo \"Enabling passwordless login\"",
      "   echo \"$encoded_value\" | sudo xxd -r - /etc/kcpassword",
      "   echo \"$encoded_value\"",
      "   sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser ${var.account_userName}",
      "fi",

      # Screensaver disable (always on)
      "echo \"Disabling screensaver...\"",
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      "defaults -currentHost write com.apple.screensaver idleTime 0",

      # Prevent sleep (always on)
      "echo \"Preventing system sleep...\"",
      "sudo systemsetup -setsleep Off 2>/dev/null",

      # Safari automation
      "if [ \"${var.enable_safari_automation}\" = \"true\" ]; then",
      "   echo \"Enabling Safari automation...\"",
      "   /Applications/Safari.app/Contents/MacOS/Safari &",
      "   SAFARI_PID=$!",
      "   disown",
      "   sleep 30",
      "   kill -9 $SAFARI_PID",
      "   sudo safaridriver --enable",
      "fi",

      # Screen lock disable
      "if [ \"${var.enable_screenlock_disable}\" = \"true\" ]; then",
      "   echo \"Disabling screen lock...\"",
      "   sysadminctl -screenLock off -password ${var.account_password}",
      "fi",

      # Spotlight disable
      "if [ \"${var.enable_spotlight_disable}\" = \"true\" ]; then",
      "   echo \"Disabling Spotlight indexing...\"",
      "   sudo mdutil -a -i off",
      "fi",

      # Install Tart guest agent
      "if [ \"${var.enable_clipboard_sharing}\" = \"true\" ]; then",
      "   echo \"Installing tart guest agent to enable Clipboard sharing...\"",
      "   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "    /opt/homebrew/bin/brew install cirruslabs/cli/tart-guest-agent",
      "   curl https://raw.githubusercontent.com/cirruslabs/macos-image-templates/refs/heads/main/data/tart-guest-agent.plist -o tart-guest-agent.plist",
      "   sudo mv tart-guest-agent.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "   sudo chown -R root:wheel /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "fi",
    ]
  }

  provisioner "shell" {
    inline = [
      "computerName=\"VM-${var.vm_name}\"",
      # Remove dots and invalid characters for LocalHostName
      "localHostName=$(echo \"$computerName\" | sed 's/[.]/-/g' | tr -cd 'a-zA-Z0-9-')",
      "sudo scutil --set HostName $computerName",
      "sudo scutil --set LocalHostName \"$localHostName\"",
      "sudo scutil --set ComputerName \"$computerName\"",
    ]
  }
}

