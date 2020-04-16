require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Lists git branches for a repository associated with the current deployment
Puppet::Functions.create_function(:'cd4pe_deployments::get_git_branches') do
  # @param repo_type
  #   The type of repo to perform the operation on. Must be one of "CONTROL_REPO" or "MODULE".
  # @example List all branches for the control repo associated with the current deployment
  #   $branches = cd4pe_deployments::get_git_branches('CONTROL_REPO')
  #   $branches.each |$branch| { out::message("Branch name: ${branch['name']} Head SHA: ${branch['sha']}") }
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Array] a list of git branches:
  #     * [Hash] a hash containing branch information
  #       * name [String] the name of the branch
  #       * sha  [String] the head SHA of the branch
  #   * error [Hash] contains error information if any
  dispatch :get_git_branches do
    required_param 'Enum["CONTROL_REPO", "MODULE"]', :repo_type
  end

  def get_git_branches(repo_type)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.get_git_branches(repo_type)
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
