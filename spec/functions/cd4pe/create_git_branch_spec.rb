require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/create_git_branch'
require 'webmock/rspec'

describe 'cd4pe_deployments::create_git_branch' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'requires 3 parameters' do
      is_expected.to run.with_params('branch').and_raise_error(ArgumentError)
    end
  end

  context 'happy' do
    include_context 'deployment'

    let(:repo_type) { 'CONTROL_REPO' }
    let(:branch_name) { 'development_b' }
    let(:commit_sha) { 'c090ea692e67405c5572af6b2a9dc5f11c9080c0' }
    let(:full_path) do
      "#{api_v1_path}/deployments/#{deployment_id}:create-git-branch?workspaceId=#{deployment_domain}"
    end

    it 'returns success on 204' do
      stub_request(:post, full_path)
        .with(
          body: {
            repoType: repo_type,
            branchName: branch_name,
            commitSha: commit_sha,
            cleanup: true,
          },
          headers: {
            'authorization' => ENV['DEPLOYMENT_TOKEN'],
          },
        )
        .to_return(status: 204, body: '')
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name, commit_sha)
        .and_return({'result' => 'success', 'error' => nil})
    end

    it 'returns error result on 4xx with a V1 error body' do
      v1_error_body = {
        'message' => 'Some error message',
        'traceId' => 'abc',
        'uriPath' => full_path,
      }
      stub_request(:post, full_path)
        .with(
          body: {
            repoType: repo_type,
            branchName: branch_name,
            commitSha: commit_sha,
            cleanup: true,
          },
          headers: {
            'authorization' => ENV['DEPLOYMENT_TOKEN'],
          },
        )
        .to_return(status: 400, body: JSON.generate(v1_error_body))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name, commit_sha)
        .and_return(
          {'result' => nil, 'error' => {'message' => 'Some error message', 'code' => '400'}},
        )
    end

    it 'raises on 5xx' do
      stub_request(:post, full_path)
        .to_return(status: 500, body: 'boom')
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name, commit_sha)
        .and_raise_error(Puppet::Error)
    end
  end
end
