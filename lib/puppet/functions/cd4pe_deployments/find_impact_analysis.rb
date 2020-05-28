require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Get information about the impacted nodes of a CD4PE Impact Analysis
Puppet::Functions.create_function(:'cd4pe_deployments::get_impact_analysis_reports') do
  # @param commit_sha
  #   The commit SHA used in the Impact Analysis reports
  # @example Get information about a specific environment in a specific IA
  #   $impact_analysis_reports = get_impact_analysis_reports('47b552dc15448b4e306fcf8df320e5124b2cbd63')
  # @return [Array] contains all Impact Analysis reports found in the pipeline
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * `rows [Array] array of hashes, one for each impacted node`
  #   * error [Hash] contains error information if any
  #
  dispatch :get_impact_analysis_reports do
    required_param 'String', :commit_sha
    optional_param 'String', :repo_name
  end

  def get_impact_analysis_reports(commit_sha, repo_name = ENV['REPO_NAME'])
    raise Puppet::Error "Unknown repo_name value" unless repo_name

    pipeline_id = call_function('cd4pe_deployments::search_pipeline', repo_name, commit_sha)

    pipeline_triggers = call_function('cd4pe_deployments::get_pipeline_trigger_events', repo_name, pipeline_id, commit_sha)

    ##Iterate through each of the pipeline triggers and look for 
    # Impact Analysis events in each of the stages.
    # Return the resulting array of reports
    pipeline_triggers.map do |pipeline|
      pipeline['eventsByStage'].map do |stage, events|
        events.select { |event| event['eventType'] == 'PEIMPACTANALYSIS' }
      end.map { |event| call_function('cd4pe_deployments::get_impact_analysis', event['impactAnalysisId'] }
    end.flatten
  end
end
