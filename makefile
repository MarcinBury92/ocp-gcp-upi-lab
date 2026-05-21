infrastructure:
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve
	./scripts/generate-ssh-config.sh

ssh:
	ssh bastion

destroy:
	cd terraform && terraform destroy -auto-approve
	truncate -s 0 ~/.ssh/known_hosts
