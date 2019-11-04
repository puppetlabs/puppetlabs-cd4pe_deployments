require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/wait_for_approval'
require 'webmock/rspec'

describe 'cd4pe_deployments::wait_for_approval' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'runs with a lambda' do
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
        .to_return(body: JSON.generate(isPending: true))
        .times(1)
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetDeploymentApprovalState', deploymentId: deployment_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(response))
        .times(1)

      is_expected.to(run.with_params(environment_name).with_lambda { |url| puts url })
    end
  end

  context 'happy' do
    include_context 'deployment'

    let(:response) do
      {
        approvalDecision: 'APPROVED',
      }
    end

    let(:response404) do
      {
        error: {
          message: 'Something went wrong, make sure your seatbelt is securely fastened',
          code: 'FunctionFailure',
        },
      }
    end

    it 'succeeds with parameters' do
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
        .to_return(body: JSON.generate(isPending: true))
        .times(1)

      stub_request(:get, ajax_url)
        .with(query: { op: 'GetDeploymentApprovalState', deploymentId: deployment_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(response))
        .times(1)

      is_expected.to(run.with_params(environment_name).with_lambda { |url| puts url })
    end

    it 'returns error response with 404 code' do
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
        .to_return(body: JSON.generate(isPending: true))
        .times(1)
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetDeploymentApprovalState', deploymentId: deployment_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: JSON.generate(response404), status: 404)
        .times(1)

      is_expected
        .to(run.with_params(environment_name).with_lambda { |url| puts url }
        .and_return(
          result: nil,
          error: {
            message: 'Something went wrong, make sure your seatbelt is securely fastened',
            code: 'FunctionFailure',
          },
        ))
    end

    it 'returns error response with 500 code' do
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
        .to_return(body: JSON.generate(isPending: true))
        .times(1)
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetDeploymentApprovalState', deploymentId: deployment_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return(body: 'nobody', status: 500)
        .times(1)
      is_expected
        .to(run.with_params(environment_name).with_lambda { |url| puts url }
        .and_return(
          result: nil,
          error: {
            message: 'Encountered exception: Received 3 server error responses from the CD4PE service at http://puppet.test:80: 500 nobody',
            code: 'EncounteredException',
          },
        ))
    end

    it 'behaves appropriately when receiving an empty response' do
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
        .to_return(body: JSON.generate(isPending: true))
        .times(1)
      stub_request(:get, ajax_url)
        .with(query: { op: 'GetDeploymentApprovalState', deploymentId: deployment_id }, headers: { 'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}" })
        .to_return({ body: JSON.generate({}), status: 200 }, body: JSON.generate(response), status: 200)
        .times(2)

      is_expected
        .to(run.with_params(environment_name).with_lambda { |url| puts url }
        .and_return(
          result: { approvalDecision: 'APPROVED' },
          error: nil,
        ))
    end
  end
end
