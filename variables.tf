variable "depends_on" {
  default = []
}
variable "os_user" {
  default     = "centos"
  description = "The OS user to be used"
}

variable "bootstrap_ip" {
  description = "The bootstrap IP to SSH to"
}

variable "bootstrap_private_ip" {
  default     = ""
  description = "used for the private ip for the bootstrap url"
}
variable "bootstrap_os_user" {
  default     = "centos"
  description = "The OS user to be used with ssh exec (only for bootstrap)"
}

variable "bootstrap_prereq-id" {
  description = "Workaround making the bootstrap install depending on an external resource (e.g. nullresource.id)"
  default     = ""
}

variable "master_private_ips" {
  type        = "list"
  description = "list of master private ips"
}

variable "masters_os_user" {
  default     = "centos"
  description = "The OS user to be used with ssh exec ( only for masters )"
}

variable "masters_prereq-id" {
  description = "Workaround making the masters install depending on an external resource (e.g. nullresource.id)"
  default     = ""
}

variable "private_agent_private_ips" {
  type        = "list"
  description = "List of private agent IPs to SSH to"
}

variable "private_agents_os_user" {
  default     = "centos"
  description = "The OS user to be used with ssh exec ( only for private agents )"
}

variable "private_agents_prereq-id" {
  description = "Workaround making the private agent install depending on an external resource (e.g. nullresource.id)"
  default     = ""
}

variable "public_agent_private_ips" {
  type        = "list"
  description = "List of public agent IPs to SSH to"
}

variable "public_agents_os_user" {
  default     = "centos"
  description = "The OS user to be used with ssh exec (only for public agents)"
}

variable "public_agents_prereq-id" {
  description = "Workaround making the public agent install depending on an external resource (e.g. nullresource.id)"
  default     = ""
}
