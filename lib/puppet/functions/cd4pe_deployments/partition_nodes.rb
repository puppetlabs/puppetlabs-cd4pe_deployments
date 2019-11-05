require 'puppet_x/puppetlabs/cd4pe_client'
require 'puppet_x/puppetlabs/cd4pe_function_result'

# @summary Partition nodes in a node group
Puppet::Functions.create_function(:'cd4pe_deployments::partition_nodes') do
  # @param node_group
  #   The node group object.
  # @param batch_size
  #   Determines the size of each partition
  # @example Create a node group then partition
  #   $parent_node_group_id = "3ed5c6c0-be33-4c62-9f41-a863a282b6ae"
  #   $test_environment = "development"
  #   $my_node_group = create_temp_node_group($parent_node_group_id, $test_environment, true)
  #   $node_partitions = partition_nodes($my_node_group, 5)
  # @return [Hash] contains the results of the function
  #   See [README.md]() for information on the CD4PEFunctionResult hash format
  #   * result [Array[Array[String]]] contains partitions of nodes
  #   * error [Hash] contains error information if any
  #
  dispatch :partition_nodes do
    required_param 'Hash', :node_group
    required_param 'Integer', :batch_size
  end

  def partition_nodes(node_group, batch_size)
    if node_group.key?(:nodes) && node_group[:nodes].is_a?(Array)
      batches = node_group[:nodes].each_slice(batch_size).to_a
      return PuppetX::Puppetlabs::CD4PEFunctionResult.create_result(batches)
    end
    raise Puppet::Error, "node_group must contain a 'nodes' key of type Array"
  rescue => exception
    PuppetX::Puppetlabs::CD4PEFunctionResult.create_exception_result(exception)
  end
end
