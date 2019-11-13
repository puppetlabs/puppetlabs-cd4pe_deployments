# @summary This deployment policy will perform a Puppet code deploy of the commit
#          associated with a Pipeline run. Puppet nodes that are scheduled to run regularly will then pick up the
#          change until all nodes in the target environment are running against the new
#          code.
plan cd4pe_deployments::eventual_consistency (
) {
  $repo_type = system::env('REPO_TYPE')
  $repo_target_branch = system::env('REPO_TARGET_BRANCH')
  $source_commit = system::env('CD4PE_SOURCE_COMMIT')
  $update_git_ref_result = cd4pe_deployments::update_git_branch_ref(
    $repo_type,
    $repo_target_branch,
    $source_commit
  )
  if $update_git_ref_result['error'] != undef {
    fail_plan($update_git_ref_result['error']['message'], $update_git_ref_result['error']['code'])
  }
  $deploy_code_result = cd4pe_deployments::deploy_code($repo_target_branch)
  cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
}
