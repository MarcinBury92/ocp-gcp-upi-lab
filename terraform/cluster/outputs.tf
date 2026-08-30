output "bootstrap_internal_ip" {
  value = google_compute_instance.bootstrap[*].network_interface[0].network_ip
}

output "master_internal_ips" {
  value = google_compute_instance.master[*].network_interface[0].network_ip
}

output "worker_internal_ips" {
  value = google_compute_instance.worker[*].network_interface[0].network_ip
}