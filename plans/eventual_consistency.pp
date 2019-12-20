# This deployment policy will perform a Puppet code deploy of the commit
# associated with a Pipeline run. Puppet nodes that are scheduled to run regularly will then pick up the
# change until all nodes in the target environment are running against the new
# code.
#
# @summary This deployment policy will perform a Puppet code deploy of the commit
#          associated with a Pipeline run. 
#
plan cd4pe_deployments::eventual_consistency (
) {
  $repo_type = system::env('REPO_TYPE')
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

  # Update the branch of the target environment to the source commit
  $update_git_ref_result = cd4pe_deployments::update_git_branch_ref(
    $repo_type,
    $repo_target_branch,
    $source_commit
  )
  if $update_git_ref_result['error'] =~ NotUndef {
    # If this is a module deployment, the update ref may have failed because we get $repo_target_branch from the node
    # group name and it may not exist on the module repository. In this case, we instead want to create a git branch
    # from the $source_commit on the module repository.
    if($repo_type == 'MODULE'){
      $git_branch_cleanup = false
      $create_git_branch_result = cd4pe_deployments::create_git_branch(
        $repo_type,
        $repo_target_branch,
        $source_commit,
        $git_branch_cleanup
      )

      if $create_git_branch_result['error'] =~ NotUndef {
        fail_plan($create_git_branch_result['error']['message'], $create_git_branch_result['error']['code'])
      }
    }
    fail_plan($update_git_ref_result['error']['message'], $update_git_ref_result['error']['code'])
  }
  # Perform the code deploy to the target environment
  $deploy_code_result = cd4pe_deployments::deploy_code($target_environment)
  $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
  if ($validate_code_deploy_result['error'] != undef) {
    fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'] )
  }
}
