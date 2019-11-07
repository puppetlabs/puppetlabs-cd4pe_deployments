plan cd4pe_deployments::eventual_consistency (
) {
  $source_commit = system::env('CD4PE_SOURCE_COMMIT')
  $target_node_group = get_node_group(system::env('NODE_GROUP_ID'))
  $update_git_ref_result = update_git_branch_ref('CONTROL_REPO', $target_node_group['environment'], $source_commit)
  if $update_git_ref_result['error'] != undef {
    fail_plan($deploy_code_result['error']['message'], $deploy_code_result['error']['code'])
  }
  $deploy_code_result = deploy_code($target_node_group['environment'])
  if $deploy_code_result['error'] != undef {
    fail_plan($deploy_code_result['error']['message'], $deploy_code_result['error']['code'])
  }
}
