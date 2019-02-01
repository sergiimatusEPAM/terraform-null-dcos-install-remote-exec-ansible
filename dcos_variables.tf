# Main Variables
variable "dcos_variant" {
  default = "open"
}

variable "dcos_download_url" {
  default =  "https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh"
}

variable "dcos_version" {
  default     = "1.12.1"
  description = "specifies which dcos version instruction to use. Options: `1.9.0`, `1.8.8`, etc. _See [dcos_download_path](https://github.com/dcos/tf_dcos_core/blob/master/download-variables.tf) or [dcos_version](https://github.com/dcos/tf_dcos_core/tree/master/dcos-versions) tree for a full list._"
}

variable "dcos_version_to_upgrade_from" {
  default     = "1.12.0"
}

variable "dcos_config_yml" {

}
