#!/bin/bash
set -e

TF_DIR="terraform/infra"
INVENTORY_FILE="ansible/inventory.ini"

command -v jq >/dev/null 2>&1 || {
  echo "[ERROR] jq is required but not installed"
  exit 1
}

echo "[INFO] Generating Ansible inventory..."

BASTION_IP=$(cd $TF_DIR && terraform output -raw bastion_ip)
SSH_USER=$(cd $TF_DIR && terraform output -raw ssh_user)

# MASTERS=$(cd $TF_DIR && terraform output -json masters_internal_ips | jq -r '.[]')
# WORKERS=$(cd $TF_DIR && terraform output -json workers_internal_ips | jq -r '.[]')

cat > "$INVENTORY_FILE" <<EOF

[bastion]
bastion ansible_host=$BASTION_IP


EOF
# [masters]
# for ip in $MASTERS; do
#  echo "$ip" >> "$INVENTORY_FILE"
# done

# cat >> "$INVENTORY_FILE" <<EOF

# [workers]
# EOF

# for ip in $WORKERS; do
#  echo "$ip" >> "$INVENTORY_FILE"
# done

cat >> "$INVENTORY_FILE" <<EOF

[all:vars]
ansible_user=$SSH_USER
ansible_ssh_private_key_file=~/.ssh/google_compute_engine
ansible_ssh_common_args='-o ProxyJump=bastion'
EOF

echo "[INFO] Inventory generated -> $INVENTORY_FILE"