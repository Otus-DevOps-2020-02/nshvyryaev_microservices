variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  default = "europe-west1"
}
variable zone {
  description = "Zone"
  default = "europe-west1-b"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
variable instance_count {
  description = "Count of instances to run"
  default     = 1
}
