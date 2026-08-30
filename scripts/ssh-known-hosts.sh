#!/bin/bash
set -e

TF_DIR="terraform/infra"

BASTION_IP=$(cd $TF_DIR && terraform output -raw bastion_ip)

# MASTERS=$(cd $TF_DIR && terraform output -json masters_internal_ips | jq -r '.[]')
# WORKERS=$(cd $TF_DIR && terraform output -json workers_internal_ips | jq -r '.[]')

echo "[INFO] adding bastion"
ssh-keyscan -H "$BASTION_IP" >> ~/.ssh/known_hosts 2>/dev/null || true

# echo "[INFO] adding masters"
# for ip in $MASTERS; do
#  ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null || true
#done

# echo "[INFO] adding workers"
#for ip in $WORKERS; do
#  ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null || true
#done

echo "[INFO] known_hosts updated"