require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Delete a git branch on your VCS
Puppet::Functions.create_function(:'cd4pe_deployments::delete_git_branch') do
  # @param repo_type
  #   The type of repo to perform the operation on. Must be one of "CONTROL_REPO" or "MODULE".
  # @param [String] branch_name
  #   The name of the branch you want to delete
  # @example Delete git branch "development_b"
  #   delete_git_branch("CONTROL_REPO", "development_b")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash] present on success:
  #     * success [Boolean] always true
  #   * error [Hash] contains error information if any (message + HTTP status code)
  dispatch :delete_git_branch do
    required_param 'Enum["CONTROL_REPO", "MODULE"]', :repo_type
    required_param 'String', :branch_name
  end

  def delete_git_branch(repo_type, branch_name)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.delete_git_branch(repo_type, branch_name)
    case response
    when Net::HTTPNoContent
      # The V1 endpoint returns no body. This hash is the contract the AJAX endpoint
      # returned and customer deployment policies branch on, so it is reconstructed here.
      # Do not "simplify" it to create_result('success') to match create_git_branch --
      # that would silently break any policy reading $result['result']['success'].
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result({ 'success' => true })
    when Net::HTTPClientError
      body = JSON.parse(response.body, symbolize_names: false)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(
        nil, body['message'], response.code
      )
    when Net::HTTPServerError
      raise Puppet::Error, "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
