#!/bin/bash
set -e
BASTION_IP=$(cd terraform && terraform output -raw bastion_ip)
USER=$(cd terraform && terraform output -raw ssh_user)
KEY="$HOME/.ssh/google_compute_engine"

mkdir -p ~/.ssh/config.d

cat > ~/.ssh/config <<EOF

Host bastion
  HostName $BASTION_IP
  User $USER
  IdentityFile $KEY
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

Host master-*
  User $USER
  IdentityFile $KEY
  ProxyJump bastion
  IdentitiesOnly yes

Host worker-*
  User $USER
  IdentityFile $KEY
  ProxyJump bastion
  IdentitiesOnly yes

EOF

echo "SSH config generated"