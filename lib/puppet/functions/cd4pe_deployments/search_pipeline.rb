require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Search which recent pipeline(s) match for a given commit SHA for a repository
Puppet::Functions.create_function(:'cd4pe_deployments::search_pipeline') do
  # @param repo_name
  #   The name of the repository
  # @param commit_sha
  #   The commit SHA to get the pipeline result for
  # @example List recent trigger events for a repository named 'control-repo'
  #   $pipeline = search_pipeline('control-repo', '47b552dc15448b4e306fcf8df320e5124b2cbd63')
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [String]: the pipelineId of the found pipeline for the provided commit SHA
  #   * error [Hash] contains error information if any
  #
  dispatch :search_pipeline do
    required_param 'String', :repo_name
    required_param 'String', :commit_sha
  end

  def search_pipeline(repo_name, commit_sha)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.list_trigger_events(repo_name)
    case response
    when Net::HTTPSuccess
      response_body = JSON.parse(response.body, symbolize_names: false)
      response_body['rows'].each do |row|
        next unless row['commitId'] == commit_sha

        return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(row['pipelineId'])
      end
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: false)
      PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  end
end
