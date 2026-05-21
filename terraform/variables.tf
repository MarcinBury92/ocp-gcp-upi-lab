variable "project_id" {}
variable "region" {
  default = "europe-central2"
}
variable "zone" {
  default = "europe-central2-a"
}

variable "ssh_user" {
  default = "devops"
}

variable "ssh_pub_key_path" {
  default = "/home/devops/.ssh/google_compute_engine.pub"
}