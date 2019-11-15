# @summary This deployment policy will deploy a source commit to the Puppet environment
#          associated with the Deployment's configured Node Group. It will then run Puppet
#          on all nodes in the environemnt.
# @param max_node_failure
#     The number of allowed failed Puppet runs that can occur before the Deployment will fail
# @param noop
#     Indicates if the Puppet run should be a noop.
plan cd4pe_deployments::direct (
  Optional[Integer] $max_node_failure,
  Boolean $noop = false,
) {
  $repo_target_branch = system::env('REPO_TARGET_BRANCH')
  $src_commit = system::env('COMMIT')
  $target_node_group_id = system::env('NODE_GROUP_ID')
  # Update the branch associated with the target environment to the source commit.
  $update_git_ref_result = cd4pe_deployments::update_git_branch_ref(
    $repo_type,
    $repo_target_branch,
    $source_commit
  )
  if $update_git_ref_result['error'] =~ NotUndef {
    fail_plan($update_git_ref_result['error']['message'], $update_git_ref_result['error']['code'])
  }

  $get_node_group_result = cd4pe_deployments::get_node_group($target_node_group_id)
  if $get_node_group_result['error'] =~ NotUndef {
    fail_plan($get_node_group_result['error']['message'], $get_node_group_result['error']['code'])
  }
  $target_environment = $get_node_group_result['result']['environment']
  # Deploy the code associated with the Node Group's environment
  $deploy_code_result = cd4pe_deployments::deploy_code($target_environment)
  $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
  if ($validate_code_deploy_result['error'] =~ NotUndef) {
    fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'])
  }

  $nodes = $get_node_group_result['result']['nodes']
  # Perform a Puppet run on all nodes in the environment
  $puppet_run_result = cd4pe_deployments::run_puppet($target_environment, $nodes, $noop)
  if $puppet_run_result['error'] =~ NotUndef {
    fail_plan($puppet_run_result['error']['message'], $puppet_run_result['error']['code'])
  }

  $node_failure_count = $puppet_run_result['result']['nodeStates']['failedNodes']
  # Fail the deployment if the number of failures exceeds the threshold
  if ($node_failure_count >= $max_node_failure) {
    fail_plan("Max node failure reached. ${node_failure_count} nodes failed.")
  }
}
