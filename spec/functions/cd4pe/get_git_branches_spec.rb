require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/get_git_branches'
require 'webmock/rspec'

describe 'cd4pe_deployments::get_git_branches' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'requires a repo_type' do
      is_expected.to run.with_params.and_raise_error(ArgumentError)
    end
  end

  context 'happy' do
    include_context 'deployment'

    let(:repo_type) { 'CONTROL_REPO' }
    let(:full_path) do
      "#{api_v1_path}/deployments/#{deployment_id}:list-git-branches" \
        "?workspaceId=#{deployment_domain}&repoType=#{repo_type}"
    end

    it 'maps headSha to sha and preserves name and commitUrl' do
      v1_body = {
        'vcsBranches' => [
          { 'name' => 'main', 'headSha' => 'sha-1', 'commitUrl' => 'https://vcs/sha-1' },
          { 'name' => 'refs/heads/dev', 'headSha' => 'sha-2', 'commitUrl' => 'https://vcs/sha-2' },
        ],
      }
      stub_request(:get, full_path)
        .with(headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 200, body: JSON.generate(v1_body))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type)
        .and_return(
          {
            'result' => [
              { 'name' => 'main', 'sha' => 'sha-1', 'commitUrl' => 'https://vcs/sha-1' },
              { 'name' => 'refs/heads/dev', 'sha' => 'sha-2', 'commitUrl' => 'https://vcs/sha-2' },
            ],
            'error' => nil,
          },
        )
    end

    it 'returns an empty result list when the repo has no branches' do
      stub_request(:get, full_path)
        .with(headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 200, body: JSON.generate({ 'vcsBranches' => [] }))
        .times(1)

      is_expected.to run.with_params(repo_type).and_return({ 'result' => [], 'error' => nil })
    end

    it 'targets the module repo when asked' do
      module_path =
        "#{api_v1_path}/deployments/#{deployment_id}:list-git-branches" \
        "?workspaceId=#{deployment_domain}&repoType=MODULE"
      stub_request(:get, module_path)
        .with(headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 200, body: JSON.generate({ 'vcsBranches' => [] }))
        .times(1)

      is_expected.to run.with_params('MODULE').and_return({ 'result' => [], 'error' => nil })
    end

    it 'returns the legacy error code on 4xx when the body carries one' do
      v1_error_body = {
        'message' => 'Deployment id=123 has no MODULE repo',
        'traceId' => 'abc',
        'uriPath' => full_path,
        'legacyCode' => 'RepoNotFound',
      }
      stub_request(:get, full_path)
        .with(headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 404, body: JSON.generate(v1_error_body))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type)
        .and_return(
          {
            'result' => nil,
            'error' => {
              'message' => 'Deployment id=123 has no MODULE repo',
              'code' => 'RepoNotFound',
            },
          },
        )
    end

    it 'falls back to the HTTP status on 4xx when the body carries no legacy code' do
      stub_request(:get, full_path)
        .with(headers: { 'authorization' => ENV['DEPLOYMENT_TOKEN'] })
        .to_return(status: 404, body: JSON.generate(v1_error_response))
        .times(1)

      is_expected
        .to run
        .with_params(repo_type)
        .and_return(
          { 'result' => nil, 'error' => { 'message' => 'Some error message', 'code' => '404' } },
        )
    end

    it 'raises on 5xx' do
      stub_request(:get, full_path)
        .to_return(status: 500, body: 'boom')
        .times(1)

      is_expected.to run.with_params(repo_type).and_raise_error(Puppet::Error)
    end
  end
end
