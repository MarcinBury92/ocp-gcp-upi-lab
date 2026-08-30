output "bastion_ip" {
  value = google_compute_address.bastion_ip.address
}
output "ssh_user" {
  value = var.ssh_user
}