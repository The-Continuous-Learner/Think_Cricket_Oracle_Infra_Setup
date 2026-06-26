#!/bin/bash
# OCI cloud-init startup script for Think Cricket.
# Rendered by Terraform templatefile() — substituted values are injected at apply time.
set -euo pipefail
exec > >(tee /var/log/startup.log) 2>&1

echo "=== Think Cricket startup: $(date) ==="

# ── Terraform-substituted values ─────────────────────────────────────────────
OCI_NAMESPACE="${oci_namespace}"
OCI_ARTIFACT_BUCKET="${oci_artifact_bucket}"
OCI_ARTIFACT_KEY="${oci_artifact_key}"
OCI_ARTIFACT_ACCESS_KEY="${oci_artifact_access_key}"
OCI_ARTIFACT_SECRET_KEY="${oci_artifact_secret_key}"
OCI_REGION="${region}"
DB_URL="${db_url}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"
APP_PORT="${app_port}"

OCI_S3_ENDPOINT="https://$OCI_NAMESPACE.compat.objectstorage.$OCI_REGION.oraclecloud.com"

# ── System setup ──────────────────────────────────────────────────────────────
echo "Installing Java 17..."
dnf install -y java-17-openjdk-headless unzip

echo "Installing AWS CLI v2 (aarch64)..."
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/awscli
/tmp/awscli/aws/install
rm -rf /tmp/awscliv2.zip /tmp/awscli

echo "Creating app user and directories..."
useradd -r -s /sbin/nologin think-cricket || true
mkdir -p /opt/think-cricket
chown think-cricket:think-cricket /opt/think-cricket

# ── Pull jar from OCI Object Storage ─────────────────────────────────────────
echo "Pulling jar from OCI bucket $OCI_ARTIFACT_BUCKET ..."
AWS_ACCESS_KEY_ID="$OCI_ARTIFACT_ACCESS_KEY" \
AWS_SECRET_ACCESS_KEY="$OCI_ARTIFACT_SECRET_KEY" \
  aws s3 cp "s3://$OCI_ARTIFACT_BUCKET/$OCI_ARTIFACT_KEY" /opt/think-cricket/app.jar \
    --endpoint-url "$OCI_S3_ENDPOINT" \
    --region "$OCI_REGION"
chown think-cricket:think-cricket /opt/think-cricket/app.jar

# ── Write env file ────────────────────────────────────────────────────────────
cat > /opt/think-cricket/.env <<EOF
SPRING_DATASOURCE_URL=$DB_URL
SPRING_DATASOURCE_USERNAME=$DB_USERNAME
SPRING_DATASOURCE_PASSWORD='$DB_PASSWORD'
SERVER_PORT=$APP_PORT
EOF
chmod 600 /opt/think-cricket/.env
chown think-cricket:think-cricket /opt/think-cricket/.env

# ── systemd service ───────────────────────────────────────────────────────────
echo "Creating systemd service..."
cat > /etc/systemd/system/think-cricket.service <<EOF
[Unit]
Description=Think Cricket Spring Boot App
After=network.target

[Service]
Type=simple
User=think-cricket
WorkingDirectory=/opt/think-cricket
EnvironmentFile=/opt/think-cricket/.env
ExecStart=/usr/bin/java -jar /opt/think-cricket/app.jar
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal
SyslogIdentifier=think-cricket

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable think-cricket
systemctl start think-cricket

echo "=== Startup complete: $(date) ==="
echo "App available on port $APP_PORT in ~30 seconds"
