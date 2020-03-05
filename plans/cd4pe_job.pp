plan cd4pe_deployments::cd4pe_job (
  TargetSpec                      $targets,
  String[1]                       $job_instance_id,
  String[1]                       $cd4pe_web_ui_endpoint,
  String[1]                       $cd4pe_job_owner,
  Optional[Array[String[1]]]      $env_vars = undef,
  Optional[String[1]]             $docker_image = undef,
  Optional[Array[String[1]]]      $docker_run_args = undef,
  Optional[String[1]]             $base_64_ca_cert = undef,
) {

  $cd4pe_token = system::env('CD4PE_TOKEN')

  return run_task(
    'cd4pe_jobs::run_cd4pe_job',
    $targets,
    'job_instance_id' => $job_instance_id,
    'cd4pe_web_ui_endpoint' => $cd4pe_web_ui_endpoint,
    'cd4pe_token' => $cd4pe_token,
    'cd4pe_job_owner' => $cd4pe_job_owner,
    'env_vars' => $env_vars,
    'docker_image' => $docker_image,
    'docker_run_args' => $docker_run_args,
    'base_64_ca_cert' => $base_64_ca_cert,
)}
