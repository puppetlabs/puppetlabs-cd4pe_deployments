# @summary This deployment policy will deploy the target control repository commit to
#          target nodes in batches. It will craete a temporary Puppet environment and
#          temporary node group to pull nodes out of the target environment and into
#          the temporary environment while the deployment is taking place.
#          When the change has been deployed to all of the target nodes, the target
#          Puppet environment is updated with the change and all the nodes are moved
#          back to the original node group.
#          When the deployment is complete, the temporary node group and temporary
#          Puppet environment is deleted, even if the deployment fails.
plan cd4pe_deployments::rolling (
  Optional[Integer] $max_node_failure,
  Integer $batch_size = 10,
  Boolean $noop = false,
  Integer $wait_seconds = 60,
  Boolean $fail_if_no_nodes = true,
) {

  $sha = system::env('COMMIT')
  $target_node_group_id = system::env('NODE_GROUP_ID')
  $target_branch = system::env('REPO_TARGET_BRANCH')

  # Get information about the target node group
  $node_group_hash = cd4pe_deployments::get_node_group($target_node_group_id)
  if ($node_group_hash[error]) {
    fail_plan("Unable to retrieve node group ${target_node_group_id}. Error: ${node_group_hash[error]}")
  }

  # Fail if we didn't get anything back or if we got an error
  if ($node_group_hash =~ Undef) {
    fail_plan("Could not find node group with ID: ${target_node_group_id}")
  } elsif ($node_group_hash[error]) {
    fail_plan("Could not retrieve target node group id: ${target_node_group_id}. Error: ${node_group_hash[error]}")
  }

  if ($node_group_hash[result] =~ Undef) {
    fail_plan("Node group with ID ${target_node_group_id} returned no data")
  } elsif ($node_group_hash[result][environment] =~ Undef) {
    fail_plan("Could not determine the environment for node group ${target_node_group_id}. No environmnent returned")
  }

  $target_environment = $node_group_hash[result][environment]

  # If the target environment requires approval, wait for that to take place
  cd4pe_deployments::wait_for_approval($target_environment) |String $url| { }

  # Warn or fail if there are no nodes in the target environmnent
  if ($node_group_hash[result][nodes] =~ Undef) {
    $msg = "No nodes found in target node group ${node_group_hash[result][name]}"
    if ($fail_if_no_nodes) {
      fail_plan("${msg}. Set fail_if_no_nodes parameter to false to prevent this deployment failure in the future")
    } else {

      $update_target_branch_result = cd4pe_deployments::update_git_branch_ref('CONTROL_REPO', $target_branch, $sha)
      if ($update_target_branch_result[error]) {
        fail_plan("Unable to update the target branch ${target_branch} to sha ${sha}")
      }

      $code_result = cd4pe_deployments::deploy_code($target_environment, $branch)
      $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($code_result)
      unless ($validate_code_deploy_result[error] =~ Undef) {
        fail_plan("Code deployment failed to target environment ${target_environment}: ${validate_code_deploy_result[error][message]}")
      }

      return "${msg}. Deploying directly to target environment and ending deployment."
    }
  }

  $branch = "ROLLING_DEPLOYMENT_${system::env('DEPLOYMENT_ID')}"
  $tmp_git_branch_result = cd4pe_deployments::create_git_branch('CONTROL_REPO', $branch,  $sha, true)
  if ($tmp_git_branch_result[error]) {
    fail_plan("Could not create temporary git branch ${branch}: ${tmp_git_branch_result[error]}")
  }

  $code_result = cd4pe_deployments::deploy_code($target_environment, $branch)
  $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($code_result)
  unless ($validate_code_deploy_result[error] =~ Undef) {
    fail_plan("Code deployment failed to target environment ${target_environment}: ${validate_code_deploy_result[error][message]}")
  }

  # Create a temporary environment node group to pin nodes to in order to run the puppet agent on
  # nodes in the target environment in batches
  $child_group = cd4pe_deployments::create_temp_node_group($target_node_group_id, $branch, true)
  if $child_group[error] {
    fail_plan("Could not create temporary node group: ${child_group[error]}")
  }

  # Break the nodes into groups and deploy the change to each group one at a time
  $batches = cd4pe_deployments::partition_nodes($node_group_hash[result], $batch_size)
  if ($batches[error]) {
    fail_plan("Could not partition nodes into groups. Error: ${batches[error]}")
  }

  $batches[result].reduce(0) |$failed_count, $batch| {
    cd4pe_deployments::pin_nodes_to_env($batch, $child_group[result][id])
    $puppet_run_result = cd4pe_deployments::run_puppet($batch, $noop)
    if $puppet_run_result[error] {
      fail_plan("Could not orchestrate puppet agent runs: ${puppet_run_result[error]}")
    }

    # If there were failed nodes, add them to the to previous failed count
    unless ($puppet_run_result[result][nodeStates][failedNodes] =~ Undef ) {
      $node_failure_total = $failed_count + $puppet_run_result[result][nodeStates][failedNodes]
    } else {
      $node_failure_total = $failed_count
    }

    if ($max_node_failure =~ Integer and $node_failure_total >= $max_node_failure) {
      #Before we fail, we should try to clean up the git branch
      $delete_tmp_git_branch_failed_deploy = cd4pe_deployments::delete_git_branch('CONTROL_REPO', $child_group[result][environment])

      $msg = "Max node failure reached. ${node_failure_total} nodes failed."
      if ($delete_tmp_git_branch_failed_deploy[error]) {
        fail_plan("${msg}. Also unable to delete the tmporary git branch ${child_group[result][environment]}")
      } else {
        fail_plan($msg)
      }
    }

    # Sleep for the specified wait time between batches
    ctrl::sleep($wait_seconds)

    $node_failure_total
  }

  $update_target_branch_result = cd4pe_deployments::update_git_branch_ref('CONTROL_REPO', $target_branch, $sha)
  if ($update_target_branch_result[error]) {
    fail_plan("Unable to update the target branch ${target_branch} to sha ${sha}")
  }

  # Clean up the temporary temporary node group
  $delete_tmp_node_group_result = cd4pe_deployments::delete_node_group($child_group[result][id])
  if ($delete_tmp_node_group_result[error]) {
    fail_plan("Unable to delete the temporary node group ${child_group[result][name]}.")
  }

  # Clean up the temporary temporary git branch
  $delete_tmp_git_branch = cd4pe_deployments::delete_git_branch('CONTROL_REPO', $child_group[result][environment])
  if ($delete_tmp_git_branch[error]) {
    fail_plan("Unable to delete the tmporary git branch ${child_group[result][environment]}")
  }
}
