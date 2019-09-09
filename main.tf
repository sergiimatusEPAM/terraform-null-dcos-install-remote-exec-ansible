/**
 * # DC/OS Ansible based remote exec install
 *
 * This module installs all DC/OS node types via a set of Ansible roles, invoked
 * from an Docker image.
 *
 * ## Prerequisites
 *
 * * Docker available on bootstrap node
 * * Access to Dockerhub. Alternatively the `mesosphere/dcos-ansible-bundle` Docker image can be made available by other means.
 * * The boostrap node is able to ssh into the other nodes, either via SSH-Agent forwarding or a statically deployed key.
 *
 * ## Re-running Ansible for upgrading or config updates
 *
 * ```bash
 * terraform taint -module dcos-install null_resource.run_ansible_from_bootstrap_node_to_install_dcos
 * terraform apply
 * ```

 * ## EXAMPLE
 *
 * ```hcl
 *  module "dcos-install" {
 *    source = "dcos-terraform/dcos-install-remote-exec-ansible/null"
 *    version = "~> 0.2.0"
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

locals {
  dcos_image_commit_flag     = "image_commit: '${var.dcos_image_commit}'"
  dcos_download_url_checksum = "download_checksum: 'sha256:${var.dcos_download_url_checksum}'"
}

resource "null_resource" "run_ansible_from_bootstrap_node_to_install_dcos" {
  triggers {
    # This should really be instance IDs of some sorts,
    # a recycled node (e.g. newly provisioned, but with same IP) would
    # not be detected.
    bootstrap_instance = "${var.bootstrap_private_ip}"

    bootstrap_ip                      = "${var.bootstrap_ip}"
    master_instances                  = "${join(",", var.master_private_ips)}"
    private_agents_instances          = "${join(",", var.private_agent_private_ips)}"
    public_agents_instances           = "${join(",", var.public_agent_private_ips)}"
    windows_private_agent_private_ips = "${join(",", var.windows_private_agent_private_ips)}"

    dcos_version      = "${var.dcos_version}"
    dcos_download_url = "${var.dcos_download_url}"
    dcos_config_yml   = "${var.dcos_config_yml}"
    dcos_variant      = "${var.dcos_variant}"

    depends_on                = "${join(",",var.depends_on)}"
    ansible_bundled_container = "${var.ansible_bundled_container}"
    ansible_additional_config = "${var.ansible_additional_config}"
    ansible_force_run         = "${var.ansible_force_run ? uuid() : ""}"
  }

  connection {
    host = "${var.bootstrap_ip}"
    user = "${var.bootstrap_os_user}"
  }

  # with a check for the case that we are on Azure checking the metadata url,
  # as long as cloud-init is not supported on the CentOS and RHEL based azure images
  provisioner "remote-exec" {
    inline = [
      "#!/usr/bin/env bash",
      "# install a may missing cloud-init and start it",
      "AZURE_METADATA_CHECK=$(curl -s -o /dev/null -w '%{http_code}' -H Metadata:true -fsSL 'http://169.254.169.254/metadata/instance?api-version=2018-10-01&format=json')",
      "if [[ \"$${AZURE_METADATA_CHECK}\" -ne 200 ]]; then",
      "which cloud-init || sudo yum install -y cloud-init",
      "sudo cloud-init init",
      "sudo cloud-init modules --mode init",
      "sudo cloud-init modules --mode config",
      "sudo cloud-init modules --mode final",
      "else",
      "which yum-config-manager || sudo yum install -y yum-utils",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo yum install -y docker-ce",
      "sudo systemctl disable firewalld.service",
      "sudo systemctl stop firewalld.service",
      "sudo systemctl enable docker.service",
      "sudo systemctl start --no-block docker.service",
      "sudo setenforce 0",
      "fi",
    ]
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
[agents_windows]
${join("\n", formatlist("%s ansible_password=%s", var.windows_private_agent_private_ips, var.windows_private_agent_passwords))}
[agents_windows:vars]
ansible_user=${var.windows_private_agent_username}
ansible_connection=winrm
ansible_winrm_transport=${var.ansible_winrm_transport}
ansible_winrm_server_cert_validation=${var.ansible_winrm_server_cert_validation}
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
${var.ansible_additional_config}
dcos:
  download: "${var.dcos_download_url}"
  ${var.dcos_download_url_checksum == "" ? "" : "${local.dcos_download_url_checksum}" }
  version: "${var.dcos_version}"
  version_to_upgrade_from: "${var.dcos_version_to_upgrade_from}"
  ${var.dcos_image_commit == "" ? "" : "${local.dcos_image_commit_flag}" }
  enterprise_dcos: ${var.dcos_variant == "ee" ? "true" : "false"}
  config:
  ${indent(4, var.dcos_config_yml)}
EOF
  }

  provisioner "remote-exec" {
    inline = [
      "# wait up to 2 minutes for docker to come up",
      "declare -i timeout; until sudo docker info >/dev/null 2>&1;do timeout=$timeout+10; test $timeout -gt 120 && exit 1;echo waiting for docker; sleep 10;done",
      "# Workaround for https://github.com/hashicorp/terraform/issues/1178: ${join(",",var.depends_on)}",
      "sudo docker pull ${var.ansible_bundled_container}",
      "sudo docker run --network=host -it --rm -v $${SSH_AUTH_SOCK}:/tmp/ssh_auth_sock -e SSH_AUTH_SOCK=/tmp/ssh_auth_sock -v /tmp/mesosphere_universal_installer_dcos.yml:/dcos.yml -v /tmp/mesosphere_universal_installer_inventory:/inventory ${var.ansible_bundled_container} ansible-playbook -i inventory dcos_playbook.yml -e @/dcos.yml -e 'dcos_cluster_name_confirmed=True'",
    ]
  }
}
