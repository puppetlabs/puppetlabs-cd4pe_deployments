require 'puppet_x/puppetlabs/cd4pe_client'

# @summary Get information about a Puppet Enterprise node group
Puppet::Functions.create_function(:'cd4pe_deployments::get_node_group') do
  # @param [String] node_group_id
  #   The ID string of the node group
  # @example Get information about node group 3ed5c6c0-be33-4c62-9f41-a863a282b6ae
  #   $node_group = get_node_group_info("3ed5c6c0-be33-4c62-9f41-a863a282b6ae")
  # @return [NodeGroup] a NodeGroup object:
  #    * `name [String] name of the node group`
  #    * `id [String] the node group's id`
  #    * `description [String] a short description of the node group`
  #    * `environment [String] the name of the environment`
  #    * `environmentTrumps [Boolean] is this an environment group?``
  #    * `parent [String] the name of the parent node group`
  #    * `rule [Array] puppetDB rule`
  #    * `classes [Hash] list of classes assigned to this node group`
  #    * `configData [Hash] node group's configuration`
  #    * `nodes [Array] list of nodes pinned to this group`
  #
  dispatch :get_node_group do
    required_param 'String', :node_group_id
  end

  def get_node_group(node_group_id)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.get_node_group(node_group_id)
    if response.code == '200' # rubocop:disable Style/GuardClause
      response_body = JSON.parse(response.body, symbolize_names: true)
      return response_body unless response_body.empty?
    else
      raise Puppet::Error, "Server returned HTTP #{response.code}"
    end
  rescue => exception
    raise Puppet::Error, "Problem getting node group information for deployment #{ENV['DEPLOYMENT_ID']}", exception.backtrace
  end
end
