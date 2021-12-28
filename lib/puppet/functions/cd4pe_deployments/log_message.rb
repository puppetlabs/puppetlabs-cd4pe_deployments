require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Add a log message as a task event when running a deployment
Puppet::Functions.create_function(:'cd4pe_deployments::log_message') do
  # @param message
  #   The message you'd like to log
  # @example Log the message "Hello I am a cool message"
  #   log_message("Hello I am a cool message")
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * success [Boolean] whether or not the operation was successful
  #   * error [Hash] contains error information if any
  #
  dispatch :log_message do
    required_param 'String', :message
  end

  def log_message(message)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.log_message(message)

    case response
    when Net::HTTPSuccess
      # log message endpoint returns a 204 and no content. Stub success result instead
      result = { "success" => true }
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(result)
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
