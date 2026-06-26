#!/bin/bash
# Think Cricket — OCI Bootstrap Script
# Run this ONCE in OCI Cloud Shell (no local tools needed):
#   OCI Console → top-right Developer Tools icon → Cloud Shell
#   Then: bash <(curl -sSL https://raw.githubusercontent.com/<your-repo>/main/bootstrap/bootstrap.sh)
#   Or upload this file and run: bash bootstrap.sh
#
# Creates:
#   - Object Storage bucket for Terraform state
#   - Object Storage bucket for build artifacts (jar)
#   - API signing key pair (for Terraform provider auth)
#   - Customer Secret Key (for S3-compatible Object Storage access)
#
# Outputs all values needed as GitHub Actions secrets.

set -euo pipefail

PROJECT="think-cricket"

echo "=== Think Cricket OCI Bootstrap ==="
echo ""

# ── Collect identity info from Cloud Shell environment ────────────────────────
# OCI Cloud Shell exposes credentials via env vars (no ~/.oci/config file).

# Tenancy OCID
if [[ -n "${OCI_TENANCY:-}" ]]; then
  TENANCY_OCID="$OCI_TENANCY"
elif [[ -f ~/.oci/config ]]; then
  TENANCY_OCID=$(grep '^tenancy=' ~/.oci/config | head -1 | cut -d= -f2 | tr -d ' ')
fi

# Region
if [[ -n "${OCI_REGION:-}" ]]; then
  REGION="$OCI_REGION"
elif [[ -f ~/.oci/config ]]; then
  REGION=$(grep '^region=' ~/.oci/config | head -1 | cut -d= -f2 | tr -d ' ')
fi

# User OCID — Cloud Shell exposes this via OCI_CS_USER_OCID
if [[ -n "${OCI_CS_USER_OCID:-}" ]]; then
  USER_OCID="$OCI_CS_USER_OCID"
elif [[ -f ~/.oci/config ]]; then
  USER_OCID=$(grep '^user=' ~/.oci/config | head -1 | cut -d= -f2 | tr -d ' ')
fi

if [[ -z "${TENANCY_OCID:-}" || -z "${USER_OCID:-}" || -z "${REGION:-}" ]]; then
  echo "ERROR: Could not determine tenancy/user/region."
  echo "Make sure you are running this inside OCI Cloud Shell."
  echo "Available env vars: OCI_TENANCY=${OCI_TENANCY:-<not set>}  OCI_REGION=${OCI_REGION:-<not set>}  OCI_CS_USER_OCID=${OCI_CS_USER_OCID:-<not set>}"
  exit 1
fi

# Object Storage namespace (account-level, not a secret)
NAMESPACE=$(oci os ns get --query data --raw-output)

echo "Tenancy : $TENANCY_OCID"
echo "User    : $USER_OCID"
echo "Region  : $REGION"
echo "NS      : $NAMESPACE"
echo ""

# ── Create Object Storage buckets ─────────────────────────────────────────────
echo "Creating bucket: ${PROJECT}-tfstate ..."
oci os bucket create \
  --name "${PROJECT}-tfstate" \
  --compartment-id "$TENANCY_OCID" \
  --versioning Enabled \
  2>/dev/null && echo "  Created." || echo "  Already exists — skipping."

echo "Creating bucket: ${PROJECT}-artifacts ..."
oci os bucket create \
  --name "${PROJECT}-artifacts" \
  --compartment-id "$TENANCY_OCID" \
  2>/dev/null && echo "  Created." || echo "  Already exists — skipping."

# ── Generate API signing key pair ─────────────────────────────────────────────
echo ""
echo "Generating API signing key pair..."
mkdir -p ~/.oci/think-cricket
openssl genrsa -out ~/.oci/think-cricket/api_key.pem 4096 2>/dev/null
chmod 600 ~/.oci/think-cricket/api_key.pem
openssl rsa -pubout \
  -in  ~/.oci/think-cricket/api_key.pem \
  -out ~/.oci/think-cricket/api_key_public.pem 2>/dev/null

# Upload the public key and capture the fingerprint
echo "Uploading public key to OCI user..."
KEY_JSON=$(oci iam user api-key upload \
  --user-id  "$USER_OCID" \
  --key "$(cat ~/.oci/think-cricket/api_key_public.pem)")
FINGERPRINT=$(echo "$KEY_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['fingerprint'])")
echo "  Fingerprint: $FINGERPRINT"

# ── Create Customer Secret Key (S3-compatible access) ─────────────────────────
echo ""
echo "Creating Customer Secret Key for S3-compatible access..."
SECRET_JSON=$(oci iam customer-secret-key create \
  --user-id      "$USER_OCID" \
  --display-name "${PROJECT}-terraform")
ACCESS_KEY=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
SECRET_KEY=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['key'])")
echo "  Done. (Secret key shown only once — captured below)"

# ── Print GitHub Secrets ───────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          GitHub Secrets — copy these now                        ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo ""
echo "── OCI Infra repo (Think_Cricket_Oracle_Infra_Setup) ──"
echo "OCI_TENANCY_OCID    = $TENANCY_OCID"
echo "OCI_USER_OCID       = $USER_OCID"
echo "OCI_FINGERPRINT     = $FINGERPRINT"
echo "OCI_REGION          = $REGION"
echo "OCI_COMPARTMENT_OCID= $TENANCY_OCID"
echo "OCI_NAMESPACE       = $NAMESPACE"
echo "OCI_STATE_BUCKET    = ${PROJECT}-tfstate"
echo "OCI_STATE_ACCESS_KEY= $ACCESS_KEY"
echo "OCI_STATE_SECRET_KEY= $SECRET_KEY"
echo "OCI_ARTIFACT_BUCKET = ${PROJECT}-artifacts"
echo ""
echo "── Think_Cricket build repo (same Customer Secret Key) ──"
echo "OCI_NAMESPACE            = $NAMESPACE"
echo "OCI_REGION               = $REGION"
echo "OCI_ARTIFACT_BUCKET      = ${PROJECT}-artifacts"
echo "OCI_ARTIFACT_ACCESS_KEY  = $ACCESS_KEY"
echo "OCI_ARTIFACT_SECRET_KEY  = $SECRET_KEY"
echo ""
echo "── OCI_PRIVATE_KEY (paste the block below including the dashes) ──"
cat ~/.oci/think-cricket/api_key.pem
echo ""
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "=== Bootstrap complete ==="
echo "Next: add the secrets above to GitHub, then push to trigger terraform apply."
