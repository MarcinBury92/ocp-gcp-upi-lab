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

resource "google_compute_router" "router" {
  name    = "ocp-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name   = "ocp-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"

  # Zmiana z ALL_SUBNETWORKS na precyzyjną listę, aby wymusić pełną kontrolę nad ocp-subnet
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # Włączamy pełne logowanie błędów i translacji (kluczowe do debugowania)
  log_config {
    enable = true
    filter = "ALL"
  }
}
# =====================================================================
# PRYWATNA STREFA DNS DLA OPENSHIFT (ZABEZPIECZA LOOKUP DLA MASZYN UPI)
# =====================================================================
resource "google_dns_managed_zone" "private_zone" {
  name        = "ocp-private-zone"
  dns_name    = "ocp.lab.local."
  description = "Prywatna strefa DNS widoczna tylko wewnatrz ocp-vpc"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

# Output potrzebny, abysmy mogli w module 'cluster' dodawac rekordy A
output "dns_zone_name" {
  value       = google_dns_managed_zone.private_zone.name
  description = "Nazwa strefy DNS do uzycia w czesci cluster"
}