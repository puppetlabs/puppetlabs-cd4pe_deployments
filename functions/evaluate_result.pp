# @summary This is a generic helper function to be used with the result from cd4pe_deployments function calls.
#          It will take the result from the function call and return an error hash if an error occurred. If no
#          error occurred, the result is returned, saving the user from having to process the hash.
# @param [Hash] result_hash
#   The result hash of any cd4pe_deployments function call.
# @return [Variant] contains the results of the function
function cd4pe_deployments::evaluate_result(Hash $result_hash){
  if $result_hash['error'] =~ NotUndef {
    fail_plan($result_hash['error']['message'], $result_hash['error']['code'])
  }
  $result_hash['result']
}
