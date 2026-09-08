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
  #       * name [String] the name of the branch, exactly as the upstream VCS reports it
  #       * sha  [String] the head SHA of the branch
  #       * commitUrl [String] web URL of the branch's head commit
  #   * error [Hash] contains error information if any (message + HTTP status code)
  dispatch :get_git_branches do
    required_param 'Enum["CONTROL_REPO", "MODULE"]', :repo_type
  end

  def get_git_branches(repo_type)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.get_git_branches(repo_type)
    case response
    when Net::HTTPSuccess
      body = JSON.parse(response.body, symbolize_names: false)
      # The V1 schema calls this field headSha; the documented return value of this
      # function has always called it sha, so remap rather than break existing plans.
      branches = (body['vcsBranches'] || []).map do |branch|
        {
          'name' => branch['name'],
          'sha' => branch['headSha'],
          'commitUrl' => branch['commitUrl'],
        }
      end
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(branches)
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
