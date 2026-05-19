resource "google_compute_instance" "bastion" {
  name         = "ocp-bastion"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}