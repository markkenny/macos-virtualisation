#!/bin/bash

# 2025 08 30 - MK Intial Commit
# 2025 09 05 - Simplify launch

set -e
echo ""

# Set a Specific VM directory if required
# currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# userHome=$( dscl . read /Users/$currentUser NFSHomeDirectory | awk '{print $2}' )
# CUSTOM_VM_DIR="$HOME/VM"
# export TART_VMS_PATH="$CUSTOM_VM_DIR"

CUSTOM_VM_DIR="$HOME/.tart/vms"

if [[ ! -d "$CUSTOM_VM_DIR" ]]; then
  echo "No Tart VMs found at $CUSTOM_VM_DIR"
  exit 1
fi

# List VMs
vms=()
for vm in "$CUSTOM_VM_DIR"/*; do
  [[ -d "$vm" ]] && vms+=("$(basename "$vm")")
done

if [[ ${#vms[@]} -eq 0 ]]; then
  echo "No VMs found in $CUSTOM_VM_DIR"
  exit 1
fi

echo "Available VMs:"
i=1
for vm in "${vms[@]}"; do
  echo " $i) $vm"
  ((i++))
done
echo ""
read -rp "Select VM number: " selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#vms[@]} )); then
  echo "Invalid selection."
  exit 1
fi

selected_vm="${vms[$((selection-1))]}"
echo "Selected: $selected_vm"
echo ""
echo "What would you like to do?"
echo "  1) Clone"
echo "  2) Launch"
echo "  3) Delete"
echo ""
read -rp "Choose action [1-3]: " action

case "$action" in
  1)
    read -rp "Enter new VM name for clone: " clone_name
    if [[ -z "$clone_name" ]]; then
      echo "Clone name cannot be empty."
      exit 1
    fi
    tart clone "$selected_vm" "$clone_name"
    tart set "$selected_vm" --random-serial --random-mac --display-refit
    echo "Cloned $selected_vm to $clone_name"
    ;;
  2)
    # tart run "$selected_vm" --dir=Home:~/
    nohup tart run "$selected_vm" --dir=Home:~/ > /dev/null 2>&1 &
    echo "Launched $selected_vm in new Tart window"
    ;;
  3)
    read -rp "Are you sure you want to delete $selected_vm? This CANNOT be undone! [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      tart delete "$selected_vm"
      echo "$selected_vm has been deleted."
    else
      echo "Delete cancelled."
    fi
    ;;
  *)
    echo "Invalid action."
    exit 1
    ;;
esac

echo ""