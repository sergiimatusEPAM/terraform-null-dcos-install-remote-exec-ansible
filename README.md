# DC/OS Ansible based remote exec install

This module installs all DC/OS node types via a set of Ansible roles, invoked
from an Docker image.

## Prerequisites

* Docker available on bootstrap node
* Access to Dockerhub. Alternatively the `mesosphere/dcos-ansible-bundle` Docker image can be made available by other means.
* The boostrap node is able to ssh into the other nodes, either via SSH-Agent forwarding or a statically deployed key.

## Re-running Ansible for upgrading or config updates

```bash
terraform taint -module dcos-install null_resource.run_ansible_from_bootstrap_node_to_install_dcos
terraform apply
```

## EXAMPLE

```hcl
 module "dcos-install" {
   source = "dcos-terraform/dcos-install-remote-exec-ansible/null"
   version = "~> 0.1.0"

   bootstrap_ip                = "${module.dcos-infrastructure.bootstrap.public_ip}"
   bootstrap_private_ip        = "${module.dcos-infrastructure.bootstrap.private_ip}"
   master_private_ips          = ["${module.dcos-infrastructure.masters.private_ips}"]
   private_agent_private_ips   = ["${module.dcos-infrastructure.private_agents.private_ips}"]
   public_agent_private_ips    = ["${module.dcos-infrastructure.public_agents.private_ips}"]

   dcos_config_yml = <<EOF
   cluster_name: "mfrickansible"
   bootstrap_url: http://${module.dcos-infrastructure.bootstrap.private_ip}:8080
   exhibitor_storage_backend: static
   master_discovery: static
   master_list: ["${join("\",\"", module.dcos-infrastructure.masters.private_ips)}"]
   EOF

   depends_on = ["${module.dcos-infrastructure.bootstrap.prereq-id}"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bootstrap\_ip | The bootstrap IP to SSH to | string | - | yes |
| bootstrap\_os\_user | The OS user to be used with ssh exec (only for bootstrap) | string | `centos` | no |
| bootstrap\_private\_ip | used for the private ip for the bootstrap url | string | `` | no |
| dcos\_config\_yml | - | string | - | yes |
| dcos\_download\_url | - | string | `https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh` | no |
| dcos\_variant | Main Variables | string | `open` | no |
| dcos\_version | specifies which dcos version instruction to use. Options: `1.9.0`, `1.8.8`, etc. _See [dcos_download_path](https://github.com/dcos/tf_dcos_core/blob/master/download-variables.tf) or [dcos_version](https://github.com/dcos/tf_dcos_core/tree/master/dcos-versions) tree for a full list._ | string | `1.12.1` | no |
| dcos\_version\_to\_upgrade\_from | - | string | `1.12.0` | no |
| depends\_on | - | list | `<list>` | no |
| master\_private\_ips | list of master private ips | list | - | yes |
| private\_agent\_private\_ips | List of private agent IPs to SSH to | list | - | yes |
| public\_agent\_private\_ips | List of public agent IPs to SSH to | list | - | yes |

