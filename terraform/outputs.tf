output "bastion_ip" {
  value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "ssh_user" {
  value = var.ssh_user
}

output "masters_internal_ips" {
  value = google_compute_instance.master[*].network_interface[0].network_ip
}

output "workers_internal_ips" {
  value = google_compute_instance.worker[*].network_interface[0].network_ip
}

