require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Creates a git branch with the given branch name and commit sha
Puppet::Functions.create_function(:'cd4pe_deployments::create_git_branch_ref') do
  # @param repo_type
  #   The type of repo to perform the operation on. Must be one of "CONTROL" or "MODULE".
  # @param branch_name
  #   The name of the branch you want to create
  # @param commit_sha
  #   The source commit SHA of the new branch
  # @example Create git branch "feature_carlscoolfeature" to commit c090ea692e67405c5572af6b2a9dc5f11c9080c0
  #   create_git_branch("feature_carlscoolfeature", "c090ea692e67405c5572af6b2a9dc5f11c9080c0")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :create_git_branch do
    required_param 'Enum["CONTROL", "MODULE"]', :repo_type
    required_param 'String', :branch_name
    required_param 'String', :commit_sha
  end

  def create_git_branch_ref(repo_type, branch_name, commit_sha)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.create_git_branch(repo_type, branch_name, commit_sha)
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
