require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Get information about a CD4PE pipeline
Puppet::Functions.create_function(:'cd4pe_deployments::get_pipeline') do
  # @param repo_type
  #   The type of the repository (CONTROL_REPO or MODULE)
  # @param repo_name
  #   The name of the repository
  # @param pipeline_id
  #   The internal ID of the pipeline for this repository
  # @example Get information about a specific pipeline for 'control-repo'
  #   $pipeline = get_pipeline('CONTROL_REPO', 'control-repo', '14hf24zme79k00mcrknrbt23sb')
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * `buildStage [String] info on the git change`
  #     * `id [String] the pipeline's id`
  #     * `name [String] the name of the pipeline`
  #     * `projectId [Hash] internal naming of the CD4PE repo`
  #     * `sources [Array] information about the source triggering the pipeline`
  #     * `stages [Array] information about all the stages in the pipeline, and their items`
  #   * error [Hash] contains error information if any
  #
  dispatch :get_pipeline do
    required_param 'String', :repo_type
    required_param 'String', :repo_name
    required_param 'String', :pipeline_id
  end

  def get_pipeline(repo_type, repo_name, pipeline_id)
    raise Puppet::Error "Invalid repo_type specified: #{repo_type}" unless ['CONTROL_REPO', 'MODULE'].include?(repo_type)

    client = PuppetX::Puppetlabs::CD4PEClient.new
    response = client.get_pipeline(repo_type, repo_name, pipeline_id)
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
