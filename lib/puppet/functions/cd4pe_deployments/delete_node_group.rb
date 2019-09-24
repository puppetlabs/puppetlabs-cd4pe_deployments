require 'puppet_x/puppetlabs/cd4pe_client'

# @summary Delete a Puppet Enterprise node group
Puppet::Functions.create_function(:'cd4pe_deployments::delete_node_group') do
  # @param [String] node_group_id
  #   The ID string of the node group
  # @example Delete node group 3ed5c6c0-be33-4c62-9f41-a863a282b6ae
  #   delete_node_group("3ed5c6c0-be33-4c62-9f41-a863a282b6ae")
  # @return [Object] success object
  #   * success [Boolean] whether or not the operation was successful
  #
  dispatch :delete_node_group do
    required_param 'String', :node_group_id
  end

  def delete_node_group(node_group_id)
    client = PuppetX::Puppetlabs::CD4PEClient.new

    response = client.delete_node_group(node_group_id)
    if response.code == '200' # rubocop:disable Style/GuardClause
      response_body = JSON.parse(response.body, symbolize_names: true)
      return response_body unless response_body.empty?
    else
      raise Puppet::Error, "Server returned HTTP #{response.code}"
    end
  rescue => exception
    raise Puppet::Error, "Problem deleting node group for deployment #{ENV['DEPLOYMENT_ID']}", exception.backtrace
  end
end
