# Main Variables
variable "dcos_variant" {
  description = "Specifies which DC/OS variant it should be: `open` (Open Source) or `ee` (Enterprise Edition)"
  default     = "open"
}

variable "dcos_download_url" {
  description = "Custom DC/OS download URL"
  default     = "https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh"
}

variable "dcos_download_url_checksum" {
  description = "Custom DC/OS download URL SHA256 Checksum. Empty string omits checking."
  default     = ""
}

variable "dcos_version" {
  default     = "1.13.5"
  description = "Specifies which DC/OS version instruction to use. Options: 1.13.5, 1.12.4, 1.11.11, etc. See dcos_download_path or dcos_version tree for a full list."
}

variable "dcos_version_to_upgrade_from" {
  description = "explicit version to upgrade from"
  default     = "1.13.0"
}

variable "dcos_image_commit" {
  description = "The commit hash for the build of DC/OS"
  default     = ""
}

variable "dcos_config_yml" {
  description = "DC/OS Configuration"
}
