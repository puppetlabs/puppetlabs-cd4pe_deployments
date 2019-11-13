function cd4pe_deployments::validate_code_deploy_status(Hash $deploy_code_result) {
  if $deploy_code_result['error'] != undef {
    fail_plan($deploy_code_result['error']['message'], $deploy_code_result['error']['code'])
  }
  $deploy_code_result['result'].each |Hash $status| {
    if $status['status'] == 'failed' {
      $error_string = String(status['error'])
      fail_plan("Failed to deploy environment: ${status['environment']} with error: ${error_string}")
    }
  }
}
