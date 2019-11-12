require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/get_node_group'
require 'webmock/rspec'

describe 'cd4pe_deployments::pin_nodes_to_env' do
  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 2 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy' do
    include_context 'deployment'

    let(:nodes) { ['carlscoolnode.one.net', 'carlscoolnode.two.net', 'carlscoolnode.three.net'] }
    let(:response) do
      { 'result' => { 'success' => true }, 'error' => nil }
    end

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'PinNodesToGroup',
            content: { deploymentId: deployment_id, nodeGroupId: node_group_id, nodes: nodes },
          },
        )
        .to_return(body: JSON.generate(response['result']), status: 200)
        .times(1)

      is_expected.to run.with_params(nodes, node_group_id).and_return(response)
    end

    it 'fails with non-200 response code' do
      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'PinNodesToGroup',
            content: { deploymentId: deployment_id, nodeGroupId: node_group_id, nodes: nodes },
          },
        )
        .to_return(body: JSON.generate(error_response), status: 404)
        .times(1)

      is_expected.to run.with_params(nodes, node_group_id).and_return(error_response)
    end
  end
end
