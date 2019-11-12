require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/deploy_code'
require 'webmock/rspec'

describe 'cd4pe_deployments::deploy_code' do
  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 1 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy' do
    include_context 'deployment'

    let(:environment_name) { 'production' }
    let(:response) do
      {
        'result' =>
        [
          {
            'environment' => 'production',
            'id' => '40',
            'status' => 'complete',
            'deploySignature' => '6130590194c84c9aadc863e4af67ce788f59ab45',
            'fileSync' => {
              'environmentCommit' => '2e0ba4e305c7b39499bb8c2e62a1a07c5f22e3ee',
              'codeCommit' => '350d908578ed214dc2465bdeae4459b6b625bb11',
            },
          },
        ],
        'error' => nil,
      }
    end

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'DeployCode',
            content: { deploymentId: deployment_id, environmentName: environment_name },
          },
        )
        .to_return(body: JSON.generate(response['result']), status: 200)
        .times(1)
      is_expected.to run.with_params(environment_name).and_return(response)
    end
  end
end
