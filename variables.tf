variable "depends_on" {
  description = "Modules are missing the depends_on feature. Faking this feature with input and output variables"
  default     = []
}

variable "bootstrap_ip" {
  description = "The bootstrap IP to SSH to"
}

variable "bootstrap_private_ip" {
  description = "Private IP bootstrap nginx is listening on. Used to build the bootstrap URL."
}

variable "bootstrap_os_user" {
  default     = "centos"
  description = "The OS user to be used with ssh exec (only for bootstrap)"
}

variable "master_private_ips" {
  type        = "list"
  description = "list of master private ips"
}

variable "private_agent_private_ips" {
  type        = "list"
  description = "List of private agent IPs to SSH to"
}

variable "public_agent_private_ips" {
  type        = "list"
  description = "List of public agent IPs to SSH to"
}

variable "ansible_bundled_container" {
  default     = "mesosphere/dcos-ansible-bundle:latest"
  description = "Docker container with bundled dcos-ansible and ansible executables"
}

variable "ansible_additional_config" {
  default     = ""
  description = "Add additional config options to ansible. This is getting merged with generated defaults. Do not specify `dcos:`"
}

variable "ansible_force_run" {
  default     = false
  description = "Run Ansible on every Terraform apply"
}
