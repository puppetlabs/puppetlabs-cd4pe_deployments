require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Create a temporary Puppet Enterprise node group
Puppet::Functions.create_function(:'cd4pe_deployments::create_temp_node_group') do
  # @param parent_node_group_id
  #   The ID string of the parent node group
  # @param environment_name
  #   The name of the environment to be associated with the temp node group
  # @param is_environment_node_group
  #   A Boolean to indicate if the node group should be an environment node group. Defaults to 'true'.
  # @example Create temp node group with parent node group id '3ed5c6c0-be33-4c62-9f41-a863a282b6ae'
  #   $parent_node_group_id = "3ed5c6c0-be33-4c62-9f41-a863a282b6ae"
  #   $test_environment = "development"
  #   create_temp_node_group($parent_node_group_id, $test_environment, true)
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Hash] Contains the new node group described by the following documentation:
  #     https://puppet.com/docs/pe/2019.1/groups_endpoint.html#response-format-01
  #   * error [Hash] Contains error info if any was encountered during the function call
  dispatch :create_temp_node_group do
    required_param 'String', :parent_node_group_id
    required_param 'String', :environment_name
    optional_param 'Boolean', :is_environment_node_group
  end

  def create_temp_node_group(parent_node_group_id, environment_name, is_environment_node_group = true)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.create_temp_node_group(parent_node_group_id, environment_name, is_environment_node_group)
    if response.code == '200'
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(response_body)
    elsif response.code =~ %r{4[0-9]+}
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    else
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end
end
