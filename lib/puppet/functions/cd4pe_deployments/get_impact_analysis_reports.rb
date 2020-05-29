require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Get all the Impact Analysis reports for a commit in the current pipeline
Puppet::Functions.create_function(:'cd4pe_deployments::get_impact_analysis_reports') do
  # @param commit_sha
  #   The commit SHA used in the Impact Analysis reports
  # @example Get information about a specific environment in a specific IA
  #   $impact_analysis_reports = get_impact_analysis_reports('47b552dc15448b4e306fcf8df320e5124b2cbd63', 'control-repo')
  # @return [Array] contains all Impact Analysis reports found in the pipeline
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash]:
  #     * `rows [Array] array of hashes, one for each report`
  #   * error [Hash] contains error information if any
  #
  dispatch :get_impact_analysis_reports do
    required_param 'String', :commit_sha
    required_param 'String', :repo_name
  end

  def get_impact_analysis_reports(commit_sha, repo_name)
    raise 'Unknown repo_name value' unless repo_name

    pipeline_id = call_function('cd4pe_deployments::search_pipeline', repo_name, commit_sha)[0]['pipelineId']

    pipeline_triggers_response = call_function('cd4pe_deployments::get_pipeline_trigger_events', repo_name, pipeline_id, commit_sha)
    raise Puppet::Error pipeline_triggers_response['error'] if pipeline_triggers_response['error']

    pipeline_triggers = pipeline_triggers_response['result']

    ## Iterate through each of the pipeline triggers and look for
    #  Impact Analysis events in each of the stages.
    #  Return the resulting array of reports
    pipeline_triggers.map { |pipeline|
      ia_events = pipeline['eventsByStage'].map { |_, events|
        # Filter out only the Impact Analysis events
        events.select { |event| event['eventType'] == 'PEIMPACTANALYSIS' }
      }.flatten # flatten into one dimensional array

      ia_events.map do |event|
        event['impactAnalysisId']
      end

      ia_events.map do |ia|
        ia_report_result = call_function('cd4pe_deployments::get_impact_analysis', ia['impactAnalysisId'])
        raise Puppet::Error ia_report_result['error'] if ia_report_result['error']

        ia_report_result['result']
      end
    }.flatten
  end
end
