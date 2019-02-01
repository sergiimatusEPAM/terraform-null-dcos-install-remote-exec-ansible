variable "depends_on" {
  default = []
}
variable "bootstrap_ip" {
  description = "The bootstrap IP to SSH to"
}

variable "bootstrap_private_ip" {
  description = "used for the private ip for the bootstrap url"
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
