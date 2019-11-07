plan cd4pe_deployments::feature_branch (
) {
  $deploy_code_result = deploy_code(system::env('CD4PE_SOURCE_BRANCH'))
  if $deploy_code_result['error'] != undef {
    fail_plan($deploy_code_result['error']['message'], $deploy_code_result['error']['code'])
  }
}
