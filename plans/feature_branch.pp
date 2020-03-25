# This deployment policy plan will perform a code deployment of an environment that
# matches the source branch for a commit. For Module deployments the plan will create
# a feature branch on the control repo that matches the source branch on the Module.
# The plan will then deploy the target environment that matches the source branch.
#
# @summary This deployment policy plan will perform a code deployment of an environment that
#          matches the source branch for a commit.
#
plan cd4pe_deployments::feature_branch (
) {
  $repo_type = system::env('REPO_TYPE')
  $src_branch_name = system::env('BRANCH')
  $environment_prefix = system::env('ENVIRONMENT_PREFIX')

  if($repo_type == 'MODULE') {
    $feature_branch_name = $src_branch_name
    $base_branch_sha = system::env('CONTROL_REPO_BASE_FEATURE_BRANCH_HEAD')
    # Create a feature branch on the control repo based on the branch that was selected when the Deployment was added
    # to the pipeline. Make the branch long lived.
    $create_branch_result = cd4pe_deployments::create_git_branch('CONTROL_REPO', $feature_branch_name, $base_branch_sha, false)
    if $create_branch_result['error'] != undef {
      fail_plan($create_branch_result['error']['message'], $create_branch_result['error']['code'])
    }
  }

  # If an environment prefix was selected on the Deployment then calculate the target environment name with this prefix
  $target_environment = $environment_prefix ? {
    '' => $src_branch_name,
    String[1] => "${environment_prefix}${src_branch_name}",
  }

  # Deploy the target environment associated with the feature branch
  $deploy_code_result = cd4pe_deployments::deploy_code($target_environment)
  $validate_code_deploy_result = cd4pe_deployments::validate_code_deploy_status($deploy_code_result)
  if ($validate_code_deploy_result['error'] != undef) {
    fail_plan($validate_code_deploy_result['error']['message'], $validate_code_deploy_result['error']['code'] )
  }
}
