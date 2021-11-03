
variable "credentials_file" { 
  default = "../secrets/cis-91.key" 
}

variable "project" {
  default = "cis-91-terraform-326406"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_disk" "zonal_persis_disk" {
  name  = "data-disk"
  type  = "pd-ssd"
  image = "ubuntu-os-cloud/ubuntu-2004-lts"
  labels = {
    environment = "dev"
  }
  description = "Zonal Persistent Disk"
  size = 100
}

resource "google_compute_attached_disk" "attaching_zonal_disk" {
  disk     = google_compute_disk.zonal_persis_disk.id
  instance = google_compute_instance.vm_instance.id
  device_name = google_compute_disk.zonal_persis_disk.name
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}