output "crc_ip" {
  value = google_compute_address.crc_ip.address
}

output "crc_zone" {
  value = var.zone
}

output "ssh_user" {
  value = var.ssh_user
}

output "crc_vm" {
  value = google_compute_instance.crc_vm.name
}

output "crc_vm_private_ip" {
  value = google_compute_instance.crc_vm.network_interface[0].network_ip
}

output "crc_vm_ssh" {
  value = "ssh ${var.ssh_user}@${google_compute_address.crc_ip.address}"
}