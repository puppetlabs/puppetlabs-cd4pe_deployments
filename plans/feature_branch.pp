# @summary This deployment policy plan will perform a code deployment of an environment that
#          matches the source branch for a commit. For Module deployments the plan will create
#          a feature branch on the control repo that matches the source branch on the Module.
#          The plan will then deploy the target environment that matches the source branch
plan cd4pe_deployments::feature_branch (
) {
  $repo_type = system::env('REPO_TYPE')
  case $repo_type {
    'CONTROL_REPO': {
      # Perform a code deploy to the environment that matches the source branch.
      $deploy_code_result = cd4pe_deployments::deploy_code(system::env('BRANCH'))
      $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
      if ($validate_code_deploy_result['error'] != undef) {
        fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'] )
      }
    }
    'MODULE': {
      $feature_branch_name = system::env('BRANCH')
      $base_branch_sha = system::env('CONTROL_REPO_BASE_FEATURE_BRANCH')
      # Create a feature branch on the control repo based on the branch that was selected when the Deployment was added
      # to the pipeline.
      $create_branch_result = cd4pe_deployments::create_git_branch('CONTROL_REPO', $feature_branch_name, $base_branch_sha)
      if $create_branch_result['error'] != undef {
        fail_plan($create_branch_result['error']['message'], $create_branch_result['error']['code'])
      }
      $environment_prefix = system::env('ENVIRONMENT_PREFIX')
      # If an environment prefix was selected on the Deployment then calculate the target environment name with this prefix
      $target_environment = $environment_prefix ? {
        '' => $feature_branch_name,
        String[1] => "${environment_prefix}${feature_branch_name}",
      }

      # Deploy the target environment associated with the feature branch
      $deploy_code_result = cd4pe_deployments::deploy_code($target_environment)
      $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
      if ($validate_code_deploy_result['error'] != undef) {
        fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'] )
      }
    }
    default: {
      fail_plan("Invalid repo type: ${repo_type}", 'InvalidRepoType')
    }
  }
}
