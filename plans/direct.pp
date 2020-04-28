# This deployment policy will deploy a source commit to the Puppet environment
# associated with the Deployment's configured Node Group. It will then run Puppet
# on all nodes in the environemnt.
#
# @summary This deployment policy will deploy a source commit to the Puppet environment
#          associated with the Deployment's configured node group and then run Puppet.
#
# @param max_node_failure
#     The number of allowed failed Puppet runs that can occur before the Deployment will fail
# @param noop
#     Indicates if the Puppet run should be a noop.
# @param fail_if_no_nodes
#     Toggles between failing or silently succeeding when the target environment group has no nodes.
plan cd4pe_deployments::direct (
  Integer $max_node_failure = 0,
  Boolean $noop = false,
  Boolean $fail_if_no_nodes = true,
) {
  $repo_target_branch = system::env('REPO_TARGET_BRANCH')
  $source_commit = system::env('COMMIT')
  $target_node_group_id = system::env('NODE_GROUP_ID')

  $get_node_group_result = cd4pe_deployments::get_node_group($target_node_group_id)
  if $get_node_group_result['error'] =~ NotUndef {
    fail_plan($get_node_group_result['error']['message'], $get_node_group_result['error']['code'])
  }

  $target_environment = $get_node_group_result['result']['environment']
  # Wait for approval if the environment is protected
  cd4pe_deployments::wait_for_approval($target_environment) |String $url| { }

  # Update the branch associated with the target environment to the source commit.
  $update_git_ref_result = cd4pe_deployments::update_git_branch_ref(
    'CONTROL_REPO',
    $repo_target_branch,
    $source_commit
  )
  if $update_git_ref_result['error'] =~ NotUndef {
    fail_plan($update_git_ref_result['error']['message'], $update_git_ref_result['error']['code'])
  }
  # Deploy the code associated with the Node Group's environment if the Deployment is approved
  $deploy_code_result = cd4pe_deployments::deploy_code($target_environment)
  $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
  if ($validate_code_deploy_result['error'] =~ NotUndef) {
    fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'])
  }

  $nodes = $get_node_group_result['result']['nodes']
  if ($nodes =~ Undef) {
    $msg = "No nodes found in target node group ${get_node_group_result['result']['name']}"
    if ($fail_if_no_nodes) {
      fail_plan("${msg}. Set fail_if_no_nodes parameter to false to prevent this deployment failure in the future")
    } else {
      return "${msg}. Deployed directly to target environment and ending deployment."
    }
  }
  # Perform a Puppet run on all nodes in the environment
  $puppet_run_result = cd4pe_deployments::run_puppet($nodes, $noop)
  if $puppet_run_result['error'] =~ NotUndef {
    fail_plan($puppet_run_result['error']['message'], $puppet_run_result['error']['code'])
  }

  if $puppet_run_result['result']['nodeStates'] =~ NotUndef {
    if $puppet_run_result['result']['nodeStates']['failedNodes'] =~ NotUndef {
      $node_failure_count = $puppet_run_result['result']['nodeStates']['failedNodes']
      # Fail the deployment if the number of failures exceeds the threshold

      if ($node_failure_count > $max_node_failure) {
        fail_plan("Max node failure reached. ${node_failure_count} nodes failed.")
      }
    }
  }
}
