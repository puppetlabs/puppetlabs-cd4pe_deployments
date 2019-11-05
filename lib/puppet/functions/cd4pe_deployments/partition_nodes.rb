require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Partition nodes in a node group
Puppet::Functions.create_function(:'cd4pe_deployments::partition_nodes') do
  # @param node_group_id
  #   The ID string of the node group
  # @param batch_size
  #   Determines the size of each partition
  # @example Partition the node group 3ed5c6c0-be33-4c62-9f41-a863a282b6ae
  #   $node_sets = partition_nodes("3ed5c6c0-be33-4c62-9f41-a863a282b6ae", 5)
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Array[Array[String]]] contains batches of nodes
  #   * error [Hash] contains error information if any
  #
  dispatch :partition_nodes do
    required_param 'String', :node_group_id
    required_param 'Integer', :batch_size
  end

  def partition_nodes(node_group_id, batch_size)
    client = PuppetX::Puppetlabs::CD4PEClient.new
    response = client.get_node_group(node_group_id)
    case response
    when Net::HTTPSuccess
      response_body = JSON.parse(response.body, symbolize_names: true)
      batches = response_body[:nodes].each_slice(batch_size).to_a
      puts "Batches: #{batches}"
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(batches)
    when Net::HTTPClientError
      response_body = JSON.parse(response.body, symbolize_names: true)
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_error_result(response_body)
    when Net::HTTPServerError
      raise Puppet::Error "Unknown HTTP Error with code: #{response.code} and body #{response.body}"
    end
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end
end
