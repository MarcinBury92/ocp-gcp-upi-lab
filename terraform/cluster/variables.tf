variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "zone" {
  type    = string
  default = "europe-central2-a"
}

variable "ssh_user" {
  type    = string
  default = "devops"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "/home/devops/.ssh/google_compute_engine.pub"
}