require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Set the approval state for an active deployment to a protected environment
Puppet::Functions.create_function(:'cd4pe_deployments::set_deployment_approval_state') do
  # @param environment_name
  #   The name of the Puppet environment to deploy. Does nothing if the specified environment is not protected.
  # @param state
  #   [Enum['PENDING_APPROVAL', APPROVED', 'DECLINED']] set the state to pending, or provide an approval decision.
  #   Does nothing if the deployment is no longer active.
  # @param username
  #   The name of the user setting the approval state. The username does not have to be a CD4PE user.
  #   Care should taken as the username is *not* validated as having special approval permissions.
  # @example Set deployment approval state
  #   set_deployment_approval_state("development", "APPROVED", "coolUser123")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :set_deployment_approval_state do
    required_param 'String', :environment_name
    required_param 'Enum["PENDING_APPROVAL", "APPROVED", "DECLINED"]', :state
    required_param 'String', :username
  end
# Should I rename state to approval_decision?
  def set_deployment_approval_state(environment_name, state, username)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.set_deployment_approval_state(environment_name, state, username);
    case response
    when Net::HTTPSuccess
      raise Bolt::PlanFailure.new("Deployment #{ENV['DEPLOYMENT_ID']} declined", 'bolt/plan-failure') if state == 'DECLINED'

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