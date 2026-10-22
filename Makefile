infrastructure:
	cd terraform/infra && terraform init -upgrade && terraform apply -auto-approve
	./scripts/wait-for-ssh.sh
	./scripts/generate-ssh-config.sh
	./scripts/ssh-known-hosts.sh
	./scripts/generate-inventory.sh

set-bastion:
	ansible-playbook -i ansible/inventory.ini ansible/bastion-set.yml
	./scripts/pulling-ign.sh

cluster:
	cd terraform/cluster && terraform apply -auto-approve

crc:
	cd terraform/crc && terraform apply -auto-approve
	./scripts/set-crc.sh

delete-crc:
	cd terraform/crc && terraform destroy -auto-approve	
	truncate -s 0 ~/.ssh/known_hosts
	
delete-bootstrap:
	gcloud compute instances delete bootstrap --zone=europe-central2-a

destroy_cluster:
	cd terraform/cluster && terraform destroy -auto-approve

destroy_infrastructure:
	cd terraform/infra && terraform destroy -auto-approve
	truncate -s 0 ~/.ssh/known_hosts
