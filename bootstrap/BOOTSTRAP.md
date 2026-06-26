# OCI Bootstrap — One-Time Setup

Run the bootstrap script once from **OCI Cloud Shell** (browser-based, no local tools needed).
It creates all bootstrap resources and prints out every GitHub secret you need.

## Run the bootstrap script

1. Open OCI Console → click the **Cloud Shell** icon (top-right, `>_`)
2. Upload `bootstrap.sh` using the Cloud Shell upload button, then run:
   ```bash
   bash bootstrap.sh
   ```
3. Copy every value printed at the end into GitHub secrets (instructions below)

That's it — no manual clicking for resource creation.

---

## Manual steps (still required via Console)

---

## 1. Create an OCI Account

Sign up at cloud.oracle.com — the Always Free tier never expires and requires no credit card to start.

---

## 2. Note Your Tenancy OCID

OCI Console → Profile (top-right) → Tenancy → copy **OCID**
→ Save as `OCI_TENANCY_OCID` GitHub secret

---

## 3. Create an API Signing Key

OCI Console → Profile → My profile → API keys → Add API key → Generate API key pair
- Download the **private key** (.pem file)
- Copy the **fingerprint** shown after upload
- Note your **user OCID** from the same page

→ Save as GitHub secrets:
  - `OCI_USER_OCID`
  - `OCI_FINGERPRINT`
  - `OCI_PRIVATE_KEY` (paste the full contents of the .pem file)

---

## 4. Note Your Region

OCI Console → top-right region selector (e.g. `ap-mumbai-1`)
→ Save as `OCI_REGION` GitHub secret

---

## 5. Note Your Compartment OCID

Use the root compartment (same as tenancy OCID) or create a new one:
OCI Console → Identity & Security → Compartments → Create Compartment

→ Save as `OCI_COMPARTMENT_OCID` GitHub secret

---

## 6. Create Object Storage Bucket for Terraform State

OCI Console → Storage → Object Storage & Archive Storage → Buckets → Create Bucket
- Name: `think-cricket-tfstate`
- Visibility: **Private**
- Leave all other defaults

---

## 7. Get Your Object Storage Namespace

OCI Console → Storage → Object Storage → top of page shows **Namespace**
(It's a short string, not an OCID)
→ Save as `OCI_NAMESPACE` GitHub secret
→ Save `think-cricket-tfstate` as `OCI_STATE_BUCKET` GitHub secret

---

## 8. Create a Customer Secret Key (S3-Compatible Access)

This gives Terraform S3-compatible access to the state bucket.

OCI Console → Profile → My profile → Customer secret keys → Generate secret key
- Name: `terraform-state`
- Copy the **secret key** immediately (shown only once)
- Note the **access key** (shown in the list)

→ Save as GitHub secrets:
  - `OCI_STATE_ACCESS_KEY`
  - `OCI_STATE_SECRET_KEY`

---

## 9. Add GitHub Secrets for the App

In your OCI infra GitHub repo → Settings → Secrets and variables → Actions:

| Secret | Value |
|--------|-------|
| `OCI_TENANCY_OCID` | From step 2 |
| `OCI_USER_OCID` | From step 3 |
| `OCI_FINGERPRINT` | From step 3 |
| `OCI_PRIVATE_KEY` | From step 3 (full PEM contents) |
| `OCI_REGION` | From step 4 (e.g. `ap-mumbai-1`) |
| `OCI_COMPARTMENT_OCID` | From step 5 |
| `OCI_NAMESPACE` | From step 7 |
| `OCI_STATE_BUCKET` | `think-cricket-tfstate` |
| `OCI_STATE_ACCESS_KEY` | From step 8 |
| `OCI_STATE_SECRET_KEY` | From step 8 |
| `JAR_S3_BUCKET` | `think-cricket-artifacts` (AWS S3 bucket) |
| `AWS_ACCESS_KEY_ID` | From AWS bootstrap (same as Think_Cricket_AWS repo) |
| `AWS_SECRET_ACCESS_KEY` | From AWS bootstrap (same as Think_Cricket_AWS repo) |
| `DB_URL` | Supabase session pooler JDBC URL |
| `DB_USERNAME` | `postgres.<supabase-project-ref>` |
| `DB_PASSWORD` | Supabase password |

---

## 10. Create GitHub Environment

GitHub repo → Settings → Environments → New environment → name it `production`
(The apply and destroy jobs require this environment for protection)

---

## Done — Push to Deploy

Push any change to `main` to trigger `terraform apply`.
The instance will be a VM.Standard.A1.Flex (4 OCPU, 24 GB RAM) — permanently free.

## Debugging

To check startup logs, use the OCI Console serial console:
OCI Console → Compute → Instances → your instance → Console connection → Launch Cloud Shell connection

Or add your SSH public key as `OCI_SSH_PUBLIC_KEY` secret and set `TF_VAR_ssh_public_key` in the workflow to enable SSH access.
