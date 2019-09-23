require 'puppet_x/puppetlabs/cd4pe_client'

# @summary Pin a list of nodes to an environment group
Puppet::Functions.create_function(:'cd4pe_deployments::pin_nodes_to_env') do
  # @param nodes
  #   List of nodes to pin to the group
  # @param node_group_id
  #   The ID string of the node group
  # @return [Object]
  #   * success [Boolean] whether or not the operation was sucessful
  #
  dispatch :pin_nodes_to_env do
    required_param 'Array', :nodes
    required_param 'String', :node_group_id
  end

  def pin_nodes_to_env(nodes, node_group_id)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.pin_nodes_to_env(nodes, node_group_id)
    if response.code == '200' # rubocop:disable Style/GuardClause
      response_body = JSON.parse(response.body, symbolize_names: true)
      return response_body unless response_body.empty?
    else
      raise Puppet::Error, "Server returned HTTP #{response.code}"
    end
  rescue => exception
    raise Puppet::Error, "Problem pinning nodes to group=#{node_group_id}, response code #{response.code}", exception.backtrace
  end
end
