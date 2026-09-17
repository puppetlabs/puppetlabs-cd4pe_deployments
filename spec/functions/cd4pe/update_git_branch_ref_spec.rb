require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/update_git_branch_ref'
require 'webmock/rspec'

describe 'cd4pe_deployments::update_git_branch_ref' do
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
      "#{api_v1_path}/deployments/#{deployment_id}:update-git-branch-ref?workspaceId=#{deployment_domain}"
    end
    let(:request_body) do
      { repoType: repo_type, branchName: branch_name, commitSha: commit_sha }
    end

    it 'returns the preserved success hash on 204' do
      stub_request(:post, full_path)
        .with(body: request_body, headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 204, body: '')
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name, commit_sha)
        .and_return({ 'result' => { 'success' => true }, 'error' => nil })
    end

    # One example per legacy code, because nothing pinned these literals before CDPE-7764 and
    # customer deployment policies branch on them.
    {
      'ParameterMissing' => 400,
      'ParameterParsing' => 400,
      'DeploymentCanceled' => 400,
      'FunctionFailure' => 400,
      'DeploymentNotFound' => 404,
      'RepoNotFound' => 404,
    }.each do |legacy_code, status|
      it "surfaces the #{legacy_code} legacy code as error.code on a #{status}" do
        v1_error_body = {
          'message' => 'Some error message',
          'traceId' => 'abc',
          'uriPath' => full_path,
          'legacyCode' => legacy_code,
        }
        stub_request(:post, full_path)
          .with(body: request_body, headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
          .to_return(status: status, body: JSON.generate(v1_error_body))
          .times(1)

        is_expected
          .to run
          .with_params(repo_type, branch_name, commit_sha)
          .and_return(
            {
              'result' => nil,
              'error' => { 'message' => 'Some error message', 'code' => legacy_code },
            },
          )
      end
    end

    it 'falls back to the HTTP status on 4xx when the body carries no legacy code' do
      stub_request(:post, full_path)
        .with(body: request_body, headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 400, body: JSON.generate(v1_error_response))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type, branch_name, commit_sha)
        .and_return(
          { 'result' => nil, 'error' => { 'message' => 'Some error message', 'code' => '400' } },
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
