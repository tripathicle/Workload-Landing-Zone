#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
cd "$REPO_ROOT"

printf '\n==> Installing linting and security tools\n'

curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | sudo bash
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | sudo bash
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sudo bash

printf '\n==> Running TFLint\n'
tflint --init || true
tflint --recursive --format compact || true

printf '\n==> Running tfsec\n'
tfsec . --format default --soft-fail || true

printf '\n==> Running Trivy filesystem scan\n'
trivy fs --security-checks vuln,config --severity HIGH,CRITICAL --exit-code 0 . || true

printf '\n==> Running TruffleHog secret scan\n'
trufflehog filesystem --directory . || true

if [[ -n "${INFRACOST_API_KEY:-}" ]]; then
  printf '\n==> Running Infracost cost estimation\n'
  infracost breakdown --path . --format json --out-file infracost.json || true
else
  printf '\n==> Skipping Infracost cost estimation because INFRACOST_API_KEY is not set.\n'
fi

echo "Terraform quality gates completed."
