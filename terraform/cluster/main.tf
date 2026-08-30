# ==============================================================================
# GOOGLE STORAGE BUCKET & IGNITION / IMAGE OBJECTS
# ==============================================================================
resource "google_storage_bucket" "ignition" {
  name                        = "${var.project_id}-ignition"
  location                    = "EUROPE-CENTRAL2"
  force_destroy               = true
  uniform_bucket_level_access = true # Włączone z powrotem, żeby GCP było szczęśliwe
}

# Automatyczne wysyłanie Twojego lokalnego pliku 1.2GB RHCOS do Bucketa GCP
resource "google_storage_bucket_object" "rhcos_image_tar" {
  name   = "rhcos-4.15.0-x86_64-gcp.x86_64.tar.gz"
  bucket = google_storage_bucket.ignition.name
  source = "${path.module}/rhcos-4.15.0-x86_64-gcp.x86_64.tar.gz"
}

resource "google_storage_bucket_object" "bootstrap_ign" {
  name   = "bootstrap.ign"
  bucket = google_storage_bucket.ignition.name
  source = "${path.module}/files/bootstrap.ign"
}

resource "google_storage_bucket_object" "master_ign" {
  name   = "master.ign"
  bucket = google_storage_bucket.ignition.name
  source = "${path.module}/files/master.ign"
}

resource "google_storage_bucket_object" "worker_ign" {
  name   = "worker.ign"
  bucket = google_storage_bucket.ignition.name
  source = "${path.module}/files/worker.ign"
}

# NOWOCZESNE I PUBLICZNE IAM (Zgodne z polityką Uniform Bucket Level Access)
resource "google_storage_bucket_iam_member" "public_viewer" {
  bucket = google_storage_bucket.ignition.name
  role   = "roles/storage.objectViewer"
  member = "allUsers" # Każdy (w tym CoreOS) może pobrać pliki tekstowe .ign
}

# ==============================================================================
# OBRAZ RHCOS (Tworzony na podstawie pliku z Twojego własnego Bucketa)
# ==============================================================================
resource "google_compute_image" "rhcos" {
  name        = "rhcos-415-0-image"
  description = "RHCOS 4.15.0 image for OpenShift UPI"

  raw_disk {
    source = "https://storage.googleapis.com/${google_storage_bucket.ignition.name}/${google_storage_bucket_object.rhcos_image_tar.name}"
  }
}

# ==============================================================================
# BOOTSTRAP (Ustawiony na COUNT = 0 - Terraform go bezpiecznie usunie)
# ==============================================================================
resource "google_compute_instance" "bootstrap" {
  count        = 0 # Zmienione z 1 na 0 - misja zakończona sukcesem!
  name         = "bootstrap"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = google_compute_image.rhcos.self_link
      size  = 100
    }
  }

  network_interface {
    network    = "ocp-vpc"
    subnetwork = "ocp-subnet"
  }

  metadata = {
    user-data = jsonencode({
      ignition = {
        version = "3.2.0"
        config = {
          replace = {
            source = "https://storage.googleapis.com/${google_storage_bucket.ignition.name}/${google_storage_bucket_object.bootstrap_ign.name}"
          }
        }
      }
    })
    ssh-keys  = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_storage_bucket_iam_member.public_viewer]
}

# ==============================================================================
# MASTERS 
# ==============================================================================
resource "google_compute_instance" "master" {
  count        = 3
  name         = "master-${count.index}"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = google_compute_image.rhcos.self_link
      size  = 100
    }
  }

  network_interface {
    network    = "ocp-vpc"
    subnetwork = "ocp-subnet"
  }

  metadata = {
    user-data = jsonencode({
      ignition = {
        version = "3.2.0"
        config = {
          replace = {
            source = "https://storage.googleapis.com/${google_storage_bucket.ignition.name}/${google_storage_bucket_object.master_ign.name}"
          }
        }
      }
    })
    ssh-keys  = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_storage_bucket_iam_member.public_viewer]
}

# ==============================================================================
# WORKERS 
# ==============================================================================
resource "google_compute_instance" "worker" {
  count        = 2
  name         = "worker-${count.index}"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = google_compute_image.rhcos.self_link
      size  = 100
    }
  }

  network_interface {
    network    = "ocp-vpc"
    subnetwork = "ocp-subnet"
  }

  metadata = {
    user-data = jsonencode({
      ignition = {
        version = "3.2.0"
        config = {
          replace = {
            source = "https://storage.googleapis.com/${google_storage_bucket.ignition.name}/${google_storage_bucket_object.worker_ign.name}"
          }
        }
      }
    })
    ssh-keys  = "${var.ssh_user}:${trimspace(file(var.ssh_pub_key_path))}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_storage_bucket_iam_member.public_viewer]
}

# ==============================================================================
# INTERNAL NATYWNY LOAD BALANCER GCP DLA OPENSHIFT KUBE-API (Port 6443)
# ==============================================================================

# 1. Grupa instancji grupująca nasze 3 Mastery
resource "google_compute_instance_group" "ocp_masters_group" {
  name        = "ocp-masters-group"
  zone        = var.zone
  description = "Niemenadżowana grupa maszyn Master dla Load Balancera"
  instances   = google_compute_instance.master[*].id

  named_port {
    name = "api"
    port = 6443
  }
  named_port {
    name = "machine-config"
    port = 22623
  }
}

# 2. Health check weryfikujący stan zdrowia Kubernetes API na Masterach
resource "google_compute_region_health_check" "ocp_api_health" {
  name               = "ocp-api-health-check"
  region             = join("-", slice(split("-", var.zone), 0, 2)) # Automatycznie wyciąga region z var.zone (np. europe-central2)
  check_interval_sec = 5
  timeout_sec        = 5

  https_health_check {
    port         = 6443
    request_path = "/readyz" # Natywny endpoint gotowości k8s API
  }
}

# 3. Definicja backendu pracującego wewnątrz naszej sieci VPC
resource "google_compute_region_backend_service" "ocp_api_backend" {
  name                  = "ocp-api-backend"
  region                = join("-", slice(split("-", var.zone), 0, 2))
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"

  backend {
    group          = google_compute_instance_group.ocp_masters_group.id
    balancing_mode = "CONNECTION"
  }

  health_checks = [google_compute_region_health_check.ocp_api_health.id]
}

# 4. Reguła przekierowania (Frontend Load Balancera) - nadaje dedykowany adres IP dla API
resource "google_compute_forwarding_rule" "ocp_api_lb" {
  name                  = "ocp-api-load-balancer"
  region                = join("-", slice(split("-", var.zone), 0, 2))
  network               = "ocp-vpc"
  subnetwork            = "ocp-subnet"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.ocp_api_backend.id
  all_ports             = false
  ports                 = ["6443", "22623"]
}

# ==============================================================================
# FIREWALL INTERNALS & HEALTH CHECKS
# ==============================================================================
resource "google_compute_firewall" "openshift_internal_traffic" {
  name        = "ocp-lab-internal-allow"
  network     = "ocp-vpc"
  description = "Zezwolenie na ruch diagnostyczny i klastrowy wewnatrz podsieci OpenShift"

  allow {
    protocol = "all"
  }

  source_ranges = ["10.10.0.0/16"]
}

# Wymóg GCP: Zakresy IP z których systemy GCP wykonują Health Checki maszyn za LB
resource "google_compute_firewall" "allow_gcp_health_checks" {
  name        = "ocp-allow-gcp-health-checks"
  network     = "ocp-vpc"
  description = "Zezwolenie sondom GCP na sprawdzanie stanu zdrowia portu 6443"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

# ==============================================================================
# AUTOMATYCZNE REKORDY DNS (TERAZ PRZEPIĘTE NA LOAD BALANCER)
# ==============================================================================

# API kieruje bezpośrednio na adres IP wewnętrznego Load Balancera GCP
resource "google_dns_record_set" "api" {
  name         = "api.ocp.lab.local."
  managed_zone = "ocp-private-zone"
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_forwarding_rule.ocp_api_lb.ip_address]
}

# API-INT również kieruje na Load Balancer
resource "google_dns_record_set" "api_int" {
  name         = "api-int.ocp.lab.local."
  managed_zone = "ocp-private-zone"
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_forwarding_rule.ocp_api_lb.ip_address]
}

# Rekordy etcd dla kazdego z 3 Masterow (wymagane, by baza etcd poprawnie utworzyla kworum)
resource "google_dns_record_set" "etcd_cluster" {
  count        = 3
  name         = "etcd-${count.index}.ocp.lab.local."
  managed_zone = "ocp-private-zone"
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_instance.master[count.index].network_interface[0].network_ip]
}

# Rekordy SRV, dzieki ktorym OpenShift automatycznie odkrywa wezly bazy etcd
resource "google_dns_record_set" "etcd_srv" {
  name         = "_etcd-server-ssl._tcp.ocp.lab.local."
  managed_zone = "ocp-private-zone"
  type         = "SRV"
  ttl          = 60
  rrdatas      = [
    "0 10 2380 etcd-0.ocp.lab.local.",
    "0 10 2380 etcd-1.ocp.lab.local.",
    "0 10 2380 etcd-2.ocp.lab.local."
  ]
}
# ==============================================================================
# NOWY REKORD DLA APLIKACJI (DYNAMICZNE IP WORKERÓW)
# ==============================================================================

# Rekord Wildcard dla aplikacji klastra (kieruje ruch na żyjące instancje Workerów)
resource "google_dns_record_set" "apps_wildcard" {
  name         = "*.apps.ocp.lab.local."
  managed_zone = "ocp-private-zone"
  type         = "A"
  ttl          = 60
  
  # Pętla automatycznie zbiera IP z zasobu google_compute_instance.worker
  rrdatas      = [for instance in google_compute_instance.worker : instance.network_interface[0].network_ip]
}