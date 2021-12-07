plan cd4pe_deployments::cd4pe_job (
  TargetSpec                      $targets,
  String[1]                       $job_instance_id,
  String[1]                       $cd4pe_web_ui_endpoint,
  String[1]                       $cd4pe_job_owner,
  Optional[Array[String[1]]]      $env_vars = undef,
  Optional[String[1]]             $docker_image = undef,
  Optional[Array[String[1]]]      $docker_run_args = undef,
  Optional[String[1]]             $docker_pull_creds = undef,
  Optional[String[1]]             $base_64_ca_cert = undef,
  Optional[Array[String[1]]]      $secret_env_vars = [],
) {
  $cd4pe_token = system::env('CD4PE_TOKEN')

  $base_task_params = {
    'job_instance_id' => $job_instance_id,
    'cd4pe_web_ui_endpoint' => $cd4pe_web_ui_endpoint,
    'cd4pe_token' => $cd4pe_token,
    'cd4pe_job_owner' => $cd4pe_job_owner,
    'env_vars' => $env_vars,
    'docker_image' => $docker_image,
    'docker_run_args' => $docker_run_args,
    'docker_pull_creds' => $docker_pull_creds,
    'base_64_ca_cert' => $base_64_ca_cert,
  }

  $task_params = if $secret_env_vars.empty {
    $base_task_params
  } else {
    $secrets_hash = $secret_env_vars.reduce({}) |$memo, $value| {
      $memo + { $value => system::env($value) }
    }
    $base_task_params + { 'secrets' => $secrets_hash }
  }

  $result_or_error = catch_errors() || {
    run_task(
      'cd4pe_jobs::run_cd4pe_job',
      $targets,
      $task_params,
    )
  }

  $result = if $result_or_error =~ Error {
    $error = $result_or_error.details['result_set'].first.error

    if $error.msg == 'secrets is not an expected parameter for this task.' {
      fail_plan(
        'You must update puppetlabs-cd4pe_jobs to version >= 1.6.0 to be able to use secrets.',
        'puppetlabs/cd4pe_deployments'
      )
    } else {
      fail_plan($result_or_error)
    }
  } else {
    $result_or_error
  }

  return $result
}
