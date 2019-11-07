plan cd4pe_deployments::eventual_consistency (
) {
  $target_node_group = get_node_group(system::env('NODE_GROUP_ID'))
  $deploy_code_result = deploy_code($target_node_group['environment'])
  if $deploy_code_result['error'] != undef {
    fail_plan($deploy_code_result['error']['message'], $deploy_code_result['error']['code'])
  }
}
