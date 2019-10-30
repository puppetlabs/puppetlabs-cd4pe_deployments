require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Delete a git branch on your VCS
Puppet::Functions.create_function(:'cd4pe_deployments::delete_git_branch') do
  # @param repo_type
  #   The type of repo to perform the operation on. Must be one of "CONTROL" or "MODULE".
  # @param [String] branch_name
  #   The name of the branch you want to delete
  # @example Delete git branch "development_b"
  #   delete_git_branch("development_b")
  # @return [Object] success object
  #   * success [Boolean] whether or not the operation was successful
  #
  dispatch :delete_git_branch do
    required_param 'Enum["CONTROL", "MODULE"]', :repo_type
    required_param 'String', :branch_name
  end

  def delete_git_branch(repo_type, branch_name)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.delete_git_branch(repo_type, branch_name)
    if response.code == '200'
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(response_body)
    elsif response.code =~ %r{4[0-9]+}
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    else
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end
end
