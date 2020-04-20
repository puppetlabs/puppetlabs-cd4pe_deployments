
require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/get_git_branches'
require 'webmock/rspec'

describe 'cd4pe_deployments::get_git_branches' do
  context 'happy' do
    include_context 'deployment'
    let(:repo_type) { 'CONTROL_REPO' }
    let(:expected_function_result) do
      {
        'result' =>
        [
          { 'name' => 'test_branch1', 'sha' => '12345' },
          { 'name' => 'test_branch2', 'sha' => '12345' },
          { 'name' => 'test_branch3', 'sha' => '12345' },
        ],
        'error' => nil,
      }
    end

    it 'succeeds with parameters' do
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetGitBranches', deploymentId: deployment_id, repoType: repo_type }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(expected_function_result['result']))
        .times(1)
      is_expected.to run.with_params(repo_type).and_return(expected_function_result)
    end
    it 'returns a non-200 response code' do
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetGitBranches', deploymentId: deployment_id, repoType: repo_type }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(error_response), status: 404)
        .times(1)

      is_expected.to run.with_params(repo_type).and_return(error_response)
    end
  end
end
