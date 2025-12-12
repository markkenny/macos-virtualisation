#!/bin/bash

# 2025 08 30 - MK Initial Commit
# 2025 09 01 - Few typos
# 2025 12 10 - Per-template .pkr.env.hcl files

set -e
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/Packs"
REQUIRED_PLAYBOOK="$SCRIPT_DIR/ansible/playbook-system-updater.yml"

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
env_file="${recipe%.pkr.hcl}.pkr.env.hcl"

echo ""
echo "Building $(basename "$recipe")"
echo ""

# Verify matching .pkr.env.hcl file exists
if [[ ! -f "$env_file" ]]; then
  echo "ERROR: Missing environment file: $(basename "$env_file")"
  echo "Expected location: $env_file"
  exit 1
fi

echo "Using environment: $(basename "$env_file")"
echo ""

packer init "$recipe"
packer validate -var-file="$env_file" "$recipe"
packer build -var-file="$env_file" "$recipe"

echo ""


