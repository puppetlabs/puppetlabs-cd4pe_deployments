require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/delete_git_branch'
require 'webmock/rspec'

describe 'cd4pe_deployments::delete_git_branch' do
  let(:ajax_op) { 'DeleteGitBranch' }

  it 'exists' do
    is_expected.not_to eq(nil)
  end

  it 'requires 1 parameters' do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  context 'happy' do
    include_context 'deployment'

    let(:git_branch) { 'development_b' }
    let(:response) do
      {
        result: {
          success: true,
        },
        error: nil,
      }
    end

    it 'succeeds with parameters' do
      stub_request(:post, ajax_url)
        .with(body: { op: ajax_op, content: { deploymentId: deployment_id, branchName: git_branch } }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(response[:result]))
        .times(1)

      is_expected.to run.with_params(git_branch).and_return(response)
    end

    it 'fails with non-200 response code' do
      stub_request(:post, ajax_url)
        .with(body: { op: ajax_op, content: { deploymentId: deployment_id, branchName: git_branch } }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(error_response), status: 404)
        .times(1)

      is_expected.to run.with_params(git_branch).and_return(error_response)
    end
  end
end
