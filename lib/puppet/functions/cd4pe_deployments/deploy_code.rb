require 'puppet_x/puppetlabs/cd4pe_client'

# @summary Performs a Puppet Enterprise Code Manager deployment for the given environment
Puppet::Functions.create_function(:'cd4pe_deployments::deploy_code') do
  # @param environment_name
  #   The name of the Puppet environment to deploy
  # @param default_branch_override
  #   Specifies a default branch to set when performing a code deploy
  # @example Perform a code deploy of the 'development' environment
  #   $my_cool_environment = "development"
  #   deploy_code($my_cool_environment)
  # @return [Array[Hash]] a list of deployment status objects
  #   * [Hash] Contains the code deployment status info
  #     * environment [String] The environment associated with the code deployment
  #     * id [String] The id used to identify the code deployment
  #     * status [String] A String representation of the code deployment status. Can be one of: 'new', 'complete', 'failed', or 'queued'.
  #     * deploySignature [String] The commit SHA of the control repo that Code Manager used to deploy code in that environment
  #     * fileSync [Hash] Commit SHAs used internally by file sync to identify the code synced to the code staging directory
  dispatch :deploy_code do
    required_param 'String', :environment_name
    optional_param 'String', :default_branch_override
  end

  def deploy_code(environment_name, default_branch_override = nil)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.deploy_code(environment_name, default_branch_override)
    if response.code == '200' # rubocop:disable Style/GuardClause
      response_body = JSON.parse(response.body, symbolize_names: true)
      return response_body unless response_body.empty?
    else
      raise Puppet::Error, "Server returned HTTP #{response.code}"
    end
  rescue => exception
    raise Puppet::Error, "Encountered code deployment error for environment #{environment_name}:, response code #{response.code}", exception.backtrace
  end
end
