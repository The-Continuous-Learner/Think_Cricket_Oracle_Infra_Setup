#!/bin/bash
# Think Cricket — OCI Budget Alerts
# Run this in OCI Cloud Shell after bootstrap.sh:
#   bash budget-alerts.sh
#
# Creates a $10/month budget with email alerts at $2, $5, and $10.
# No prerequisites — OCI Budgets work out of the box (unlike AWS which requires
# "Enable Billing Alerts" in billing preferences first).

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
BUDGET_AMOUNT=10   # monthly budget cap in USD
PROJECT="think-cricket"

# ── Read inputs ───────────────────────────────────────────────────────────────
echo "=== Think Cricket OCI Budget Alerts ==="
echo ""
read -rp "Enter email address for alerts: " ALERT_EMAIL

# ── Get tenancy OCID ──────────────────────────────────────────────────────────
# OCI Cloud Shell exposes credentials via env vars, not ~/.oci/config
if [[ -n "${OCI_TENANCY:-}" ]]; then
  TENANCY_OCID="$OCI_TENANCY"
elif [[ -f ~/.oci/config ]]; then
  TENANCY_OCID=$(grep '^tenancy=' ~/.oci/config | head -1 | cut -d= -f2 | tr -d ' ')
fi

if [[ -z "${TENANCY_OCID:-}" ]]; then
  echo "ERROR: Could not determine tenancy OCID."
  echo "Make sure you are running this inside OCI Cloud Shell."
  exit 1
fi

echo ""
echo "Tenancy : $TENANCY_OCID"
echo "Email   : $ALERT_EMAIL"
echo "Budget  : \$$BUDGET_AMOUNT/month"
echo ""

# ── Create budget ─────────────────────────────────────────────────────────────
# target-type ALL covers the entire tenancy — no --targets list needed.
echo "Creating budget..."
TMPFILE=$(mktemp)
if ! oci budgets budget create \
  --compartment-id  "$TENANCY_OCID" \
  --display-name    "${PROJECT}-monthly-budget" \
  --description     "Monthly spend guard for Think Cricket OCI resources" \
  --amount          "$BUDGET_AMOUNT" \
  --reset-period    MONTHLY \
  --target-type     ALL > "$TMPFILE" 2>&1; then
  echo "ERROR: oci budgets budget create failed:"
  cat "$TMPFILE"
  rm -f "$TMPFILE"
  exit 1
fi

echo "  Raw response (first 3 lines):"
head -3 "$TMPFILE"
BUDGET_ID=$(python3 -c "import sys,json; print(json.load(open('$TMPFILE'))['data']['id'])")
rm -f "$TMPFILE"
echo "  Budget created: $BUDGET_ID"

# ── Create alert rules ────────────────────────────────────────────────────────
# ABSOLUTE threshold = dollar amount (not percentage).
# ACTUAL type        = fires on real spend (not forecast).

create_alert() {
  local name="$1"
  local amount="$2"
  local message="$3"

  oci budgets alert-rule create \
    --budget-id      "$BUDGET_ID" \
    --display-name   "$name" \
    --threshold      "$amount" \
    --threshold-type ABSOLUTE \
    --type           ACTUAL \
    --recipients     "$ALERT_EMAIL" \
    --message        "$message" \
    > /dev/null
  echo "  Alert at \$$amount created."
}

echo "Creating alert rules..."
create_alert "${PROJECT}-alert-2"  2  "Think Cricket OCI spend has reached \$2 this month."
create_alert "${PROJECT}-alert-5"  5  "Think Cricket OCI spend has reached \$5 this month."
create_alert "${PROJECT}-alert-10" 10 "Think Cricket OCI spend has reached \$10 this month — at budget limit."

echo ""
echo "=== Done ==="
echo "Budget alerts active. You will receive emails at \$2, \$5, and \$10 monthly spend."
echo "View in OCI Console → Billing & Cost Management → Budgets"
