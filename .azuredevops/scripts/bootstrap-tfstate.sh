#!/usr/bin/env bash
set -euo pipefail

resource_group=""
location=""
storage_account=""
container=""

usage() {
  echo "Usage: $0 --resource-group <name> --location <region> --storage-account <name> --container <name>"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group)
      resource_group="$2"
      shift 2
      ;;
    --location)
      location="$2"
      shift 2
      ;;
    --storage-account)
      storage_account="$2"
      shift 2
      ;;
    --container)
      container="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      ;;
  esac
done

if [[ -z "$resource_group" || -z "$location" || -z "$storage_account" || -z "$container" ]]; then
  echo "Missing required arguments."
  usage
fi

az group create \
  --name "$resource_group" \
  --location "$location" \
  --output none

if ! az storage account show --name "$storage_account" --resource-group "$resource_group" >/dev/null 2>&1; then
  az storage account create \
    --name "$storage_account" \
    --resource-group "$resource_group" \
    --location "$location" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --allow-blob-public-access false \
    --output none
fi

az storage container create \
  --name "$container" \
  --account-name "$storage_account" \
  --auth-mode login \
  --public-access off \
  --output none

echo "Terraform state storage is ready: $resource_group / $storage_account / $container"
