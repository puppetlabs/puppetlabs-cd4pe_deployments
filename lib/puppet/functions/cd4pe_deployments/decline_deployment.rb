require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Decline a "pending approval" active deployment to a protected environment.
# Typically consumed inside the block passed into `wait_for_approval`.
# Related: `approve_deployment`
Puppet::Functions.create_function(:'cd4pe_deployments::decline_deployment') do
  # @param environment_name
  #   The name of the Puppet environment to deploy. Does nothing if the specified environment is not protected.
  # @param username
  #   The name of the user declining the deployment. The username does not have to be a CD4PE user.
  #   Care should taken as the username is *not* validated as having special approval permissions.
  # @example Decline approval
  #   decline_deployment("development", "coolUser123")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :decline_deployment do
    required_param 'String', :environment_name
    required_param 'String', :username
  end

  def decline_deployment(environment_name, username)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    state = 'DECLINED'
    response = client.set_deployment_approval_state(environment_name, state, username)
    case response
    when Net::HTTPSuccess
      raise Bolt::PlanFailure.new("Deployment #{ENV['DEPLOYMENT_ID']} declined", 'bolt/plan-failure')
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
