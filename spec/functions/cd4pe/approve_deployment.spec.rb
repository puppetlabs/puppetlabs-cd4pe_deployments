require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/approve_deployment'
require 'webmock/rspec'

describe 'cd4pe_deployments::approve_deployment' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'requires 2 parameters' do
      is_expected.to run.with_params.and_raise_error(ArgumentError)
    end

    context 'happy' do
      include_context 'deployment'

      let(:ajax_op) { 'SetDeploymentApprovalState' }
      let(:state) { 'APPROVED' }
      let(:username) { 'I am a user approving' }
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
                deploymentId: deployment_id,
                environment: environment_name,
                state: state,
                username: username,
              },
            },
            headers: {
              'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}",
            },
          )
          .to_return(body: JSON.generate(response['result']))
          .times(1)

        is_expected.to run.with_params(environment_name, username).and_return(response)
      end

      it 'fails with non-200 response code' do
        stub_request(:post, ajax_url)
          .with(
            body: {
              op: ajax_op,
              content: {
                deploymentId: deployment_id,
                environment: environment_name,
                state: state,
                username: username,
              },
            },
            headers: {
              'authorization' => "Bearer token #{ENV['DEPLOYMENT_TOKEN']}",
            },
          )
          .to_return(body: JSON.generate(error_response), status: 404)
          .times(1)

        is_expected.to run.with_params(environment_name, username).and_return(error_response)
      end
    end
  end
end
