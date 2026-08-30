#!/bin/bash
set -e

BASTION_IP=$(cd terraform/infra && terraform output -raw bastion_ip)
KEY="$HOME/.ssh/google_compute_engine"

echo "[INFO] waiting for bastion SSH..."

until ssh -i "$KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=5 \
  devops@$BASTION_IP "echo ok" 2>/dev/null; do
    echo "waiting..."
    sleep 5
done

echo "[INFO] bastion ready"