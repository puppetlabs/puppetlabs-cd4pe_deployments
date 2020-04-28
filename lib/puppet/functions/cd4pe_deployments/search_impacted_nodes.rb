require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Get information about the impacted nodes of a CD4PE Impact Analysis
Puppet::Functions.create_function(:'cd4pe_deployments::search_impacted_nodes') do
  # @param environment_result_id
  #   The internal environment_result_id of an analysed code environment in the IA
  # @example Get information about a specific environment in a specific IA
  #   $impacted_nodes = search_impacted_nodes(517)
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * `rows [Array] array of hashes, one for each impacted node`
  #   * error [Hash] contains error information if any
  #
  dispatch :search_impacted_nodes do
    required_param 'Integer', :environment_result_id
  end

  def search_impacted_nodes(environment_result_id)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.search_impacted_nodes(environment_result_id)
    case response
    when Net::HTTPSuccess
      response_body = JSON.parse(response.body, symbolize_names: false)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(response_body)
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
