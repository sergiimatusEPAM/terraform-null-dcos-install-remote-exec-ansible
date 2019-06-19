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
   version = "~> 0.2.0"

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
| bootstrap\_ip | The bootstrap IP to SSH to | string | n/a | yes |
| bootstrap\_private\_ip | Private IP bootstrap nginx is listening on. Used to build the bootstrap URL. | string | n/a | yes |
| dcos\_config\_yml | DC/OS Configuration | string | n/a | yes |
| master\_private\_ips | list of master private ips | list | n/a | yes |
| private\_agent\_private\_ips | List of private agent IPs to SSH to | list | n/a | yes |
| public\_agent\_private\_ips | List of public agent IPs to SSH to | list | n/a | yes |
| ansible\_additional\_config | Add additional config options to ansible. This is getting merged with generated defaults. Do not specify `dcos:` | string | `""` | no |
| ansible\_bundled\_container | Docker container with bundled dcos-ansible and ansible executables | string | `"mesosphere/dcos-ansible-bundle:latest"` | no |
| ansible\_force\_run | Run Ansible on every Terraform apply | string | `"false"` | no |
| bootstrap\_os\_user | The OS user to be used with ssh exec (only for bootstrap) | string | `"centos"` | no |
| dcos\_download\_url | Custom DC/OS download URL | string | `"https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh"` | no |
| dcos\_image\_commit | The commit hash for the build of DC/OS | string | `""` | no |
| dcos\_variant | Specifies which DC/OS variant it should be: `open` (Open Source) or `ee` (Enterprise Edition) | string | `"open"` | no |
| dcos\_version | Specifies which DC/OS version instruction to use. Options: 1.13.1, 1.12.3, 1.11.10, etc. See dcos_download_path or dcos_version tree for a full list. | string | `"1.12.1"` | no |
| dcos\_version\_to\_upgrade\_from | explicit version to upgrade from | string | `"1.12.0"` | no |
| depends\_on | Modules are missing the depends_on feature. Faking this feature with input and output variables | list | `<list>` | no |

