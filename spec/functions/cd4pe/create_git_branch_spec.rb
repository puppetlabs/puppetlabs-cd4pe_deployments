require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/create_git_branch'
require 'webmock/rspec'

describe 'cd4pe_deployments::create_git_branch' do
  let(:ajax_op) { 'CreateGitBranch' }

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
    let(:git_branch) { 'development_b' }
    let(:commit_sha) { 'c090ea692e67405c5572af6b2a9dc5f11c9080c0' }
    let(:response) do
      {
        'result' => {
          'success' => true,
        },
        'error' => nil,
      }
    end

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(
          body: {
            op: ajax_op,
            content: {
              repoType: repo_type,
              deploymentId: deployment_id,
              branchName: git_branch,
              commitSha: commit_sha,
              cleanup: true,
            },
          },
          headers: {
            'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}",
          },
        )
        .to_return(body: JSON.generate(response['result']))
        .times(1)

      is_expected.to run.with_params(repo_type, git_branch, commit_sha).and_return(response)
    end

    it 'fails with non-200 response code' do
      stub_request(:post, ajax_url)
        .with(
          body: {
            op: ajax_op,
            content: {
              repoType: repo_type,
              deploymentId: deployment_id,
              branchName: git_branch,
              commitSha: commit_sha,
              cleanup: true,
            },
          },
          headers: {
            'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}",
          },
        )
        .to_return(body: JSON.generate(error_response), status: 404)
        .times(1)

      is_expected.to run.with_params(repo_type, git_branch, commit_sha).and_return(error_response)
    end
  end
end
