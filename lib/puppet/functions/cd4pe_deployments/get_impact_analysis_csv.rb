require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Download the CSV report of an impact analysis run
Puppet::Functions.create_function(:'cd4pe_deployments::get_impact_analysis_csv') do
  # @param id
  #   The internal ID of the Impact Analysis
  # @example Get the CSV for an Impact Analysis report as a string
  #   $ia_csv = get_impact_analysis_csv(2452)
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash] of GetImpactAnalysisCsv operation
  #   * error [Hash] contains error information if any
  #
  dispatch :get_impact_analysis_csv do
    required_param 'Integer', :id
  end

  def get_impact_analysis_csv(id)
    client = PuppetX::Puppetlabs::CD4PEClient.new
    
    response = client.get_impact_analysis_csv(id)

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
