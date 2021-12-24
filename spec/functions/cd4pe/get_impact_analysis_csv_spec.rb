require 'spec_helper'
require_relative '../../../lib/puppet/functions/cd4pe_deployments/get_impact_analysis_csv'
require 'webmock/rspec'

describe 'cd4pe_deployments::get_impact_analysis_csv' do
  context 'table steaks' do
    include_context 'deployment'

    it 'exists' do
      is_expected.not_to eq(nil)
    end

    it 'requires 1 parameter' do
      is_expected.to run.with_params.and_raise_error(ArgumentError)
      is_expected.to run.with_params("more than", "one param").and_raise_error(ArgumentError)
    end

    context 'happy' do
      include_context 'deployment'

      let(:response) do
        {
          'result' => {
            'success' => true,
          },
          'error' => nil,
        }
      end

      it 'succeeds with message parameter' do
        id = 1234
        full_path =  "#{api_v1_path}/impact-analysis/#{id}/csv?workspaceId=#{deployment_domain}"
        stub_request(:get, full_path)
          .with(
            headers: {
              'authorization' => ENV['DEPLOYMENT_TOKEN'],
            },
          )
          .to_return(body: JSON.generate(response['result']))
          .times(1)

        is_expected.to run.with_params(id).and_return(response)
      end

      it 'fails with non-200 response code' do
        id = 1234
        full_path =  "#{api_v1_path}/impact-analysis/#{id}/csv?workspaceId=#{deployment_domain}"
        stub_request(:get, full_path)
          .with(
            headers: {
              'authorization' => ENV['DEPLOYMENT_TOKEN'],
            },
          )
          .to_return(body: JSON.generate(error_response), status: 404)
          .times(1)

        is_expected.to run.with_params(id).and_return(error_response)
      end
    end
  end
end