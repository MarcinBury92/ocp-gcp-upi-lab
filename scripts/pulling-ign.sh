#!/bin/bash
set -e
TF_DIR="terraform/infra"
BASTION_IP=$(cd $TF_DIR && terraform output -raw bastion_ip)
SSH_USER=$(cd $TF_DIR && terraform output -raw ssh_user)
REMOTE_PATH="/home/${SSH_USER}/openshift-install/cluster"
LOCAL_PATH="/mnt/c/Users/marci/ocp-gcp-upi-lab/terraform/cluster/files"

rm -rf "${LOCAL_PATH}/*.ign"
# Pobierz pliki .ign z servera bastion
scp "${SSH_USER}@bastion:${REMOTE_PATH}/*.ign" "${LOCAL_PATH}/"

printf "\n${LOCAL_PATH}:\n"

(cd "${LOCAL_PATH}" && ls -l *.ign)
