require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/create_temp_node_group'
require 'webmock/rspec'

describe 'cd4pe_deployments::create_temp_node_group' do
  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 2 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy' do
    include_context 'deployment'

    let(:environment_name) { 'development' }
    let(:parent_node_group_id) { '3ed5c6c0-be33-4c62-9f41-a863a282b6ae' }

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => ENV['DEPLOYMENT_TOKEN'] },
          body: {
            op: 'CreateTempNodeGroup',
            content: {
              deploymentId: deployment_id,
              environmentName: environment_name,
              parentNodeGroupId: parent_node_group_id,
              isEnvironmentNodeGroup: true,
            },
          },
        )
        .to_return(status: 200)
        .times(1)
      is_expected.to run.with_params(parent_node_group_id, environment_name)
    end
  end
end
