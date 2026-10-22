resource "google_compute_network" "crc_vpc" {
  name                    = "crc-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "crc_subnet" {
  name          = "crc-subnet"
  ip_cidr_range = "10.20.0.0/24"
  region        = var.region
  network       = google_compute_network.crc_vpc.id
}

resource "google_compute_firewall" "crc_allow_ssh" {
  name    = "crc-allow-ssh"
  network = google_compute_network.crc_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "crc_allow_icmp" {
  name    = "crc-allow-icmp"
  network = google_compute_network.crc_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "crc_router" {
  name    = "crc-router"
  region  = var.region
  network = google_compute_network.crc_vpc.id
}

resource "google_compute_router_nat" "crc_nat" {
  name                               = "crc-nat"
  router                             = google_compute_router.crc_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.crc_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ALL"
  }
}

resource "google_compute_address" "crc_ip" {
  name   = "crc-ip"
  region = var.region
}

resource "google_compute_instance" "crc_vm" {
  name         = "crc-vm"
  machine_type = "n2-standard-8"
  zone         = var.zone

  advanced_machine_features {
    enable_nested_virtualization = true
  }

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-9"
      size  = 120
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.crc_subnet.id

    access_config {
      nat_ip = google_compute_address.crc_ip.address
    }
  }

  metadata = {
    enable-oslogin = "FALSE"

    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }

  scheduling {
    automatic_restart = true
  }
}