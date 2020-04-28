# @summary This is a helper function to be used with the result from the `deploy_code` function.
#          It will take the result from a code deploy and return an error hash if an error occurred or if
#          any of the code deployments failed.
# @param [Hash] deploy_code_result
#   The results of the code deployment from calling the `deploy_code` function.
#   See the `deploy_code` docs for more info on the value of this object
# @return [Hash] contains the results of the code deployment
function cd4pe_deployments::validate_code_deploy_status(Hash $deploy_code_result) {

  # If the deploy_code_result contains an error Hash then just return it as the error
  if $deploy_code_result['error'] != undef {
    return $deploy_code_result
  }
  $deploy_code_result['result'].each |Hash $status| {
    if $status['status'] == 'failed' {
      $error_string = $status['deploymentError']
      $error_msg = "Failed to deploy environment: ${status['environment']} with error: ${error_string}"
      $code = 'FailedCodeDeployment'
      $error_result = {
        'error' => {
          'message' => $error_msg,
          'code' => $code
        }
      }
      return $error_result
    }
  }
  $error_result = {
    'error' => undef
  }
  return $error_result
}
