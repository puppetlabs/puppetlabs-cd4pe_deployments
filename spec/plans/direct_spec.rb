require 'spec_helper'
require 'rspec/mocks'
require 'webmock/rspec'

describe 'cd4pe_deployments::direct', if: Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0') do
  context 'happy' do
    include_context 'deployment'
    let(:repo_type) { 'CONTROL_REPO' }
    let(:test_nodes) do
      [
        'foo.example.com',
        'bar.example.com',
        'biz.example.com',
      ]
    end

    let(:puppet_run_request) do
      {
        environmentName: nil,
        deploymentId: deployment_id,
        nodes: test_nodes,
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

    let(:update_git_branch_response) do
      {
        'result' => {
          'success' => true,
        },
        'error' => nil,
      }
    end

    let(:node_group_response) do
      {
        'result' => {
          'environment' => environment_name,
          'nodes' => test_nodes,
        },
        'error' => nil,
      }
    end

    let(:no_nodes_node_group_response) do
      {
        'result' => {
          'environment' => environment_name,
          'nodes' => nil,
        },
        'error' => nil,
      }
    end

    let(:deploy_code_response) do
      {
        'result' =>
        [
          {
            'environment' => 'development',
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

    before(:each) do
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetNodeGroupInfo', deploymentId: deployment_id, nodeGroupId: node_group_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(node_group_response['result']))
        .times(1)

      stub_request(:post, ajax_url)
        .with(
          body: {
            op: 'UpdateGitRef',
            content: {
              repoType: repo_type,
              deploymentId: deployment_id,
              branchName: environment_name,
              commitSha: commit,
            },
          },
          headers: {
            'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}",
          },
        )
        .to_return(body: JSON.generate(update_git_branch_response['result']))
        .times(1)

      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'SetDeploymentPendingApproval',
            content: {
              deploymentId: deployment_id,
              environment: environment_name,
            },
          },
        )
        .to_return(body: JSON.generate(isPending: false))
        .times(1)

      stub_request(:post, ajax_url)
        .with(
          headers: { 'content-type' => 'application/json', 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" },
          body: {
            op: 'DeployCode',
            content: { deploymentId: deployment_id, environmentName: environment_name },
          },
        )
        .to_return(body: JSON.generate(deploy_code_response['result']), status: 200)
        .times(1)

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
    end

    it 'runs the plan with default args' do
      expect(run_plan('cd4pe_deployments::direct', {})).to be_ok
    end

    it 'runs the plan with fail_if_no_nodes disabled' do
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetNodeGroupInfo', deploymentId: deployment_id, nodeGroupId: node_group_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(no_nodes_node_group_response['result']))
        .times(1)
      expect(run_plan('cd4pe_deployments::direct', 'fail_if_no_nodes' => false)).to be_ok
    end
  end
end
