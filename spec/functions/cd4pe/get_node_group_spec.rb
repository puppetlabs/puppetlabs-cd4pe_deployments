require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/get_node_group'
require 'webmock/rspec'

describe 'cd4pe_deployments::get_node_group' do
  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 1 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy path' do
    include_context 'deployment'

    it 'returns false if servers response is empty' do
      stub_request(:get, ajax_url)
        .with(query: { :op => 'GetNodeGroupInfo', :deploymentId => ENV['DEPLOYMENT_ID'], :nodeGroupId => node_group_id}, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}"})
        .to_return(body: JSON.generate({ success: true }))
        .times(1)

      is_expected.to run.with_params(node_group_id)
    end
  end
end