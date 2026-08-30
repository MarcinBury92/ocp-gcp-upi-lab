#!/bin/bash
set -e

TF_DIR="terraform/infra"

BASTION_IP=$(cd $TF_DIR && terraform output -raw bastion_ip)
SSH_USER=$(cd $TF_DIR && terraform output -raw ssh_user)

KEY="$HOME/.ssh/google_compute_engine"

SSH_CONFIG="$HOME/.ssh/config"

echo "[INFO] Generating SSH config..."

cat > "$SSH_CONFIG" <<EOF

Host bastion
  HostName $BASTION_IP
  User $SSH_USER
  IdentityFile $KEY
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

EOF

chmod 600 "$SSH_CONFIG"

echo "[INFO] SSH config generated -> $SSH_CONFIG"
echo "[INFO] Bastion: $BASTION_IP"


# Host 10.10.0.*
#  User $SSH_USER
#  ProxyJump bastion
#  IdentityFile $KEY
#  IdentitiesOnly yes
#  StrictHostKeyChecking accept-new