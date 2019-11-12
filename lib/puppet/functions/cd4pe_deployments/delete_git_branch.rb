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
  # @return [Object] success object
  #   * success [Boolean] whether or not the operation was successful
  #
  dispatch :delete_git_branch do
    required_param 'Enum["CONTROL_REPO", "MODULE"]', :repo_type
    required_param 'String', :branch_name
  end

  def delete_git_branch(repo_type, branch_name)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.delete_git_branch(repo_type, branch_name)
    case response
    when Net::HTTPSuccess
      response_body = JSON.parse(response.body, symbolize_names: false)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(response_body)
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
