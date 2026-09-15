require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/delete_git_branch'
require 'webmock/rspec'

describe 'cd4pe_deployments::delete_git_branch' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'requires 2 parameters' do
      is_expected.to run.with_params.and_raise_error(ArgumentError)
    end
  end

  context 'happy' do
    include_context 'deployment'

    let(:repo_type) { 'MODULE' }
    let(:branch_name) { 'development_b' }
    let(:full_path) do
      "#{api_v1_path}/deployments/#{deployment_id}:delete-git-branch?workspaceId=#{deployment_domain}"
    end

    it 'returns the preserved success hash on 204' do
      stub_request(:post, full_path)
        .with(
          body: { repoType: repo_type, branchName: branch_name },
          headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] },
        )
        .to_return(status: 204, body: '')
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name)
        .and_return({ 'result' => { 'success' => true }, 'error' => nil })
    end

    it 'returns the legacy error code on 4xx when the body carries one' do
      v1_error_body = {
        'message' => 'Deployment not found: id=123',
        'traceId' => 'abc',
        'uriPath' => full_path,
        'legacyCode' => 'DeploymentNotFound',
      }
      stub_request(:post, full_path)
        .with(
          body: { repoType: repo_type, branchName: branch_name },
          headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] },
        )
        .to_return(status: 404, body: JSON.generate(v1_error_body))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name)
        .and_return(
          {
            'result' => nil,
            'error' => {
              'message' => 'Deployment not found: id=123',
              'code' => 'DeploymentNotFound',
            },
          },
        )
    end

    it 'falls back to the HTTP status on 4xx when the body carries no legacy code' do
      stub_request(:post, full_path)
        .with(
          body: { repoType: repo_type, branchName: branch_name },
          headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] },
        )
        .to_return(status: 404, body: JSON.generate(v1_error_response))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name)
        .and_return(
          { 'result' => nil, 'error' => { 'message' => 'Some error message', 'code' => '404' } },
        )
    end

    it 'raises on 5xx' do
      stub_request(:post, full_path)
        .to_return(status: 500, body: 'boom')
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name)
        .and_raise_error(Puppet::Error)
    end
  end
end
