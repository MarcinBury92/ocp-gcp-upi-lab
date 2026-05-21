resource "google_compute_network" "vpc" {
  name                    = "ocp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "ocp-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "bastion_ip" {
  name   = "bastion-ip"
  region = var.region
}

resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }
}

resource "google_compute_instance" "master" {
  count        = 3
  name         = "master-${count.index}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 100
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }
}

resource "google_compute_instance" "worker" {
  count        = 2
  name         = "worker-${count.index}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 100
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }
}