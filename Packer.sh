#!/bin/bash

# 2025 08 30 - MK Intial Commit

set -e
echo ""

# Set a Specific VM directory if required
# currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# userHome=$( dscl . read /Users/$currentUser NFSHomeDirectory | awk '{print $2}' )
# CUSTOM_VM_DIR="$HOME/VM"
# export TART_VMS_PATH="$CUSTOM_VM_DIR"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/Packs"
REQUIRED_PLAYBOOK="$SCRIPT_DIR/ansible/playbook-system-updater.yml"


# Load .env file if present
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  . "$SCRIPT_DIR/.env"
  export PACKER_VAR_mac_username
  export PACKER_VAR_mac_password
  export PACKER_VAR_jamf_invitation_id
  export PACKER_VAR_jamf_url
  set +a
else
  echo "FAIL: .env file not found."
  exit 1
fi

# Check for ANSIBLE playbook file
if [[ ! -f "$REQUIRED_PLAYBOOK" ]]; then
  echo "Required playbook not found: $REQUIRED_PLAYBOOK"
  exit 1
fi

if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo "Templates directory not found: $TEMPLATES_DIR"
  exit 1
fi

# Build list of .pkr.hcl files
recipes=()
for f in "$TEMPLATES_DIR"/*.pkr.hcl; do
  [ -e "$f" ] || continue  # skip if none found
  recipes+=("$f")
done

if [[ ${#recipes[@]} -eq 0 ]]; then
  echo "No .pkr.hcl files found in $TEMPLATES_DIR"
  exit 1
fi

echo ""
echo "PACKER BUILDER"
echo "Available recipes:"
i=1
for recipe in "${recipes[@]}"; do
  printf "%2d) %s\n" "$i" "$(basename "$recipe")"
  i=$((i+1))
done

read -rp "Select recipe number to build: " selection

if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#recipes[@]} )); then
  echo "Invalid selection."
  exit 1
fi

recipe="${recipes[$((selection-1))]}"
echo ""
echo "Building $(basename "$recipe")"
echo ""

packer validate "$recipe"
packer init "$recipe"
packer build \
-var "mac_username=$PACKER_VAR_mac_username" \
-var "mac_password=$PACKER_VAR_mac_password" \
-var "jamf_url=$PACKER_VAR_jamf_url" \
-var "jamf_invitation_id=$PACKER_VAR_jamf_invitation_id" \
"$recipe"
echo ""

