/**
 * DC/OS Ansible based remote exec install
 * ============
 * This module installs all DC/OS node types via a set of Ansible roles, invoked
 * from an Docker image.
 *
 * ## Prerequisites
 * * Docker available on bootstrap node
 * * Access to Dockerhub. Alternatively the `mesosphere/dcos-ansible-bundle` Docker image can be made available by other means.
 * * The boostrap node is able to ssh into the other nodes, either via SSH-Agent forwarding or a statically deployed key.
 *
 * EXAMPLE
 * -------
 * ```hcl
 *  module "dcos-install" {
 *    source = "dcos-terraform/dcos-install-remote-exec-ansible/null"
 *    version = "~> 0.1.0"
 *
 *    bootstrap_ip                = "${module.dcos-infrastructure.bootstrap.public_ip}"
 *    bootstrap_private_ip        = "${module.dcos-infrastructure.bootstrap.private_ip}"
 *    master_private_ips          = ["${module.dcos-infrastructure.masters.private_ips}"]
 *    private_agent_private_ips   = ["${module.dcos-infrastructure.private_agents.private_ips}"]
 *    public_agent_private_ips    = ["${module.dcos-infrastructure.public_agents.private_ips}"]
 *
 *    dcos_config_yml = <<EOF
 *    cluster_name: "mfrickansible"
 *    bootstrap_url: http://${module.dcos-infrastructure.bootstrap.private_ip}:8080
 *    exhibitor_storage_backend: static
 *    master_discovery: static
 *    master_list: ["${join("\",\"", module.dcos-infrastructure.masters.private_ips)}"]
 *    EOF
 *
 *    depends_on = ["${module.dcos-infrastructure.bootstrap.prereq-id}"]
 *}
 * ```
 */

resource "null_resource" "run_ansible_from_bootstrap_node_to_install_dcos" {


  triggers {
    # This should really be instance IDs of some sorts,
    # a recycled node (e.g. newly provisioned, but with same IP) would
    # not be detected.
    bootsrap_instance = "${var.bootstrap_private_ip}"
    master_instances = "${join(",", var.master_private_ips)}"
    private_agents_instances = "${join(",", var.private_agent_private_ips)}"
    public_agents_instances = "${join(",", var.public_agent_private_ips)}"
  }

  connection {
    host = "${var.bootstrap_ip}"
    user = "${var.bootstrap_os_user}"
  }

  provisioner "file" {
      destination = "/tmp/mesosphere_universal_installer_inventory"
      content = <<EOF
[bootstraps]
${var.bootstrap_private_ip}
[masters]
${join("\n", var.master_private_ips)}
[agents_private]
${join("\n", var.private_agent_private_ips)}
[agents_public]
${join("\n", var.public_agent_private_ips)}
[bootstraps:vars]
node_type=bootstrap
[masters:vars]
node_type=master
dcos_legacy_node_type_name=master
[agents_private:vars]
node_type=agent
dcos_legacy_node_type_name=slave
[agents_public:vars]
node_type=agent_public
dcos_legacy_node_type_name=slave_public
[agents:children]
agents_private
agents_public
[dcos:children]
bootstraps
masters
agents
agents_public
EOF
    }

  provisioner "file" {
  destination = "/tmp/mesosphere_universal_installer_dcos.yml"

  content = <<EOF
---
dcos:
  download: "${var.dcos_download_url}"
  version: "${var.dcos_version}"
  version_to_upgrade_from: "${var.dcos_version_to_upgrade_from}"
  enterprise_dcos: ${var.dcos_variant == "ee" ? "true" : "false"}
  config:
    ${indent(4, var.dcos_config_yml)}
EOF
  }

    provisioner "remote-exec" {
      inline = [
        "# Workaround for https://github.com/hashicorp/terraform/issues/1178: ${join(",",var.depends_on)}",
        "sudo docker run -it --rm -v $${SSH_AUTH_SOCK}:/tmp/ssh_auth_sock -e SSH_AUTH_SOCK=/tmp/ssh_auth_sock -v /tmp/mesosphere_universal_installer_dcos.yml:/dcos.yml -v /tmp/mesosphere_universal_installer_inventory:/inventory mesosphere/dcos-ansible-bundle:latest ansible-playbook -i inventory dcos_playbook.yml -e @/dcos.yml -e 'dcos_cluster_name_confirmed=True'"
      ]
  }
}
