require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/run_puppet'
require 'webmock/rspec'

describe 'cd4pe_deployments::run_puppet' do
  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 2 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy' do
    include_context 'deployment'

    let(:environment_name) { 'production' }
    let(:puppet_run_request) do
      {
        environmentName: environment_name,
        deploymentId: deployment_id,
        nodes: [
          'test1.example.com',
          'test2.example.com',
          'test3.example.com',
        ],
        withNoop: false,
      }
    end
    let(:run_puppet_response) do
      {
        'job' => {
          'id' => 'https://test-pe:8143/orchestrator/v1/jobs/1',
          'name' => '1',
        },
      }
    end

    # Since we only use state from the job status we don't really need to stub the entire object

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'RunPuppet',
            content: puppet_run_request,
          },
        )
        .to_return(body: JSON.generate(run_puppet_response), status: 200)
        .times(1)

      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'GetPuppetRunStatus',
            content: { deploymentId: deployment_id, jobId: run_puppet_response['job'] },
          },
        )
        .to_return({ body: JSON.generate(state: 'running'), status: 200 }, body: JSON.generate(state: 'finished'), status: 200)
        .times(2)

      is_expected.to run.with_params(puppet_run_request[:nodes], puppet_run_request[:withNoop], environment_name).and_return('result' => { 'state' => 'finished' }, 'error' => nil)
    end
  end
end
