# TODO: What would be a good, or any possible, value to fake a 'depdens'
# chain with this module? Null-resources to not seem to have provide any thing useful here.
# As of right now it seems fine, as its the last one executed anyway, but that could change in the future!
# output "depends" {
#   description = "Modules are missing the depends_on feature. Faking this feature with input and output variables"
#   value       = "${null_resource.run_ansible_from_bootstrap_node_to_install_dcos.remote-exec}"
# }

