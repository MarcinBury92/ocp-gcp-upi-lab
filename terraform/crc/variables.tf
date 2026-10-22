variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-central2-a"
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "devops"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
  default     = "/home/devops/.ssh/google_compute_engine.pub"
}
