require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Update a given git branch's HEAD ref to a new commit SHA
Puppet::Functions.create_function(:'cd4pe_deployments::update_git_branch_ref') do
  # @param branch_name
  #   The name of the branch you want to update
  # @param commit_sha
  #   The commit SHA that will become the branch's new HEAD
  # @example Update git branch "production" to commit c090ea692e67405c5572af6b2a9dc5f11c9080c0
  #   update_git_branch_ref("production", "c090ea692e67405c5572af6b2a9dc5f11c9080c0")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :update_git_branch_ref do
    required_param 'String', :branch_name
    required_param 'String', :commit_sha
  end

  def update_git_branch_ref(branch_name, commit_sha)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.update_git_branch_ref(branch_name, commit_sha)
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
