require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Run Puppet using the Puppet Orchestrator for a set of nodes in a given environment
Puppet::Functions.create_function(:'cd4pe_deployments::run_puppet') do
  # @param environment_name
  #   The name of the Puppet environment to deploy
  # @param nodes
  #   The list of nodes to Run puppet on
  # @param noop
  #   A Boolean to run Puppet in Noop mode. Defaults to 'false'.
  # @param concurrency
  #   The number of nodes to concurrently run Puppet on. Defaults to the Puppet Orchestrator default.
  # @example Run Puppet on nodes in the 'development' environment
  #   $my_cool_environment = "development"
  #   $nodes = ["test1.example.com", "test2.example.com", "test3.example.com"]
  #   run_puppet($my_cool_environment, $nodes, false, 2)
  # @return [Hash] contains the results of the function
  #   * result [Hash] This contains data described by the following documentation:
  #     https://puppet.com/docs/pe/latest/orchestrator_api_jobs_endpoint.html#get-jobs-job-id
  #   * error [Hash] Contains error info if any was encountered during the function call

  dispatch :run_puppet do
    required_param 'String', :environment_name
    required_param 'Array[String]', :nodes
    optional_param 'Boolean', :noop
    optional_param 'Integer', :concurrency
  end

  def run_puppet(environment_name, nodes, concurrency = nil, noop = false)
    @client = PuppetX::Puppetlabs::CD4PEClient.new
    response = @client.run_puppet(environment_name, nodes, concurrency, noop)
    if response.code == '200'
      create_job_res = JSON.parse(response.body, symbolize_names: true)
      return wait_for_puppet_run(create_job_res[:job])
    elsif response.code =~ %r{4[0-9]+}
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    else
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end

  def wait_for_puppet_run(job)
    terminal_states = ['stopped', 'failed', 'finished']
    current_state = nil
    until terminal_states.include? current_state
      run_status_res = @client.get_puppet_run_status(job)
      if run_status_res.code == '200'
        run_status = JSON.parse(run_status_res.body, symbolize_names: true)
        current_state = run_status[:state]
      elsif run_status_res.code =~ %r{4[0-9]+}
        error_body = JSON.parse(run_status_res.body, symbolize_names: true)
        return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(error_body)
      else
        raise Puppet::Error "Unknown HTTP Error with code: #{run_status_res.code} and body #{run_status_res.body} while polling Puppet run status"
      end
      Kernel.sleep(3)
    end
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(run_status)
  end
end
