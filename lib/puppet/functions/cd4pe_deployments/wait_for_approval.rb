require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'
require 'bolt/error'

# @summary Blocks further plan execution until the deployment is approved in CD4PE
#
# Blocks further plan execution until the deployment is approved in CD4PE and takes a lambda that is executed once
# at the start of the wait time. The lambda includes the "url" which is a link to the approval page for the deployment. If
# the max approval window is exceeded (24 hours) or approval is declined, a Bolt::PlanFailure is raised, otherwise a result
# is returned to the user.
Puppet::Functions.create_function(:'cd4pe_deployments::wait_for_approval') do
  # @param environment_name
  # The name of the environment to wait for approval on. Does nothing if the specified environment is not protected.
  # @param block
  #   Takes a block that provides the URL to the deployment's approval page
  # @example Notify Slack users that approval is needed
  #   wait_for_approval("development") |String $url| {
  #     run_task("slack::notify", "#it-ops", "Please review this deployment for approval: ${url}")
  #   }
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * approvalDecision [Enum['APPROVED', 'DECLINED']] whether the deployment was approved or declined
  #   * error [Hash] contains error information if any
  #
  dispatch :wait_for_approval do
    required_param 'String', :environment_name
    block_param :block
  end

  def wait_for_approval(environment_name, &block)
    init_client

    response = attempt_set_deployment_pending(environment_name)

    unless response['result']['isPending']
      return response
    end

    approval_response = approval_pending?
    return approval_response unless approval_response['error'].nil?

    if approval_response['result'].empty? # rubocop:disable Style/GuardClause
      url = approval_url
      block.call(url) if block_given? && !url.nil? # rubocop:disable Performance/RedundantBlockCall

      while approval_response['result'].empty?
        approval_response = approval_pending?
        sleep(5)
      end

      raise Bolt::PlanFailure.new("Approval timed out for deployment #{ENV['DEPLOYMENT_ID']}", 'bolt/plan-failure') if approval_response['result'].empty?
      raise Bolt::PlanFailure.new("Deployment #{ENV['DEPLOYMENT_ID']} declined", 'bolt/plan-failure') if approval_decision(approval_response) == 'DECLINED'
      approval_response
    end
  end

  def approval_pending?
    response = @client.get_approval_state
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
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end

  def approval_url
    "#{@client.config[:scheme]}://#{@client.config[:server]}:#{@client.config[:port]}/#{@client.config[:deployment_owner]}/deployments/#{@client.config[:deployment_id]}"
  end

  def attempt_set_deployment_pending(environment_name)
    response = @client.deployment_pending_approval(environment_name)
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
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end

  def approval_decision(response)
    response['result']['approvalDecision']
  end

  def init_client
    @client = PuppetX::Puppetlabs::CD4PEClient.new
  end
end
