require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Performs a Puppet Enterprise Code Manager deployment for the given environment
Puppet::Functions.create_function(:'cd4pe_deployments::deploy_code') do
  # @param environment_name
  #   The name of the Puppet environment to deploy
  # @param default_branch_override
  #   Specifies a default branch to set when performing a code deploy
  # @example Perform a code deploy of the 'development' environment
  #   $my_cool_environment = "development"
  #   deploy_code($my_cool_environment)
  # @return [Hash] contains the results of the function
  #   * result [Array[Hash]] a list of deployment status objects
  #     * environment [String] The environment associated with the code deployment
  #     * id [String] The id used to identify the code deployment
  #     * status [String] A String representation of the code deployment status. Can be one of: 'new', 'complete', 'failed', or 'queued'.
  #     * deploySignature [String] The commit SHA of the control repo that Code Manager used to deploy code in that environment
  #     * fileSync [Hash] Commit SHAs used internally by file sync to identify the code synced to the code staging directory
  #   * error [Hash] Contains error info if any was encountered during the function call

  dispatch :deploy_code do
    required_param 'String', :environment_name
    optional_param 'String', :default_branch_override
  end

  def deploy_code(environment_name, default_branch_override = nil)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.deploy_code(environment_name, default_branch_override)
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
