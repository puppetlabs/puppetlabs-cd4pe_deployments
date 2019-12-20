require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Creates a git branch with the given branch name and commit SHA
Puppet::Functions.create_function(:'cd4pe_deployments::create_git_branch') do
  # @param repo_type
  #   The type of repo to perform the operation on. Must be one of "CONTROL_REPO" or "MODULE".
  # @param branch_name
  #   The name of the branch you want to create
  # @param commit_sha
  #   The source commit SHA of the new branch
  # @param cleanup
  #   Whether or not CD4PE should clean up the branch at the end of the deployment. Defaults to true
  # @example Create git branch "feature_carlscoolfeature" to commit c090ea692e67405c5572af6b2a9dc5f11c9080c0
  #   create_git_branch("CONTROL_REPO", "feature_carlscoolfeature", "c090ea692e67405c5572af6b2a9dc5f11c9080c0")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :create_git_branch do
    required_param 'Enum["CONTROL_REPO", "MODULE"]', :repo_type
    required_param 'String', :branch_name
    required_param 'String', :commit_sha
    optional_param 'Boolean', :cleanup
  end

  def create_git_branch(repo_type, branch_name, commit_sha, cleanup = true)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.create_git_branch(repo_type, branch_name, commit_sha, cleanup)
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
