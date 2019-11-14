require 'spec_helper'
require 'bolt/error'
describe 'cd4pe_deployments::validate_code_deploy_status' do
  context 'happy' do
    let(:deploy_status_good) do
      {
        'result' =>
        [
          {
            'environment' => 'production',
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
    let(:deploy_status_failed) do
      {
        'result' =>
        [
          {
            'error' => { 'details' => 'stuff failed', 'kind' => 'bad-error' },
            'environment' => 'production',
            'id' => '40',
            'status' => 'failed',
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
    let(:deploy_status_failed_message) { 'Failed to deploy environment: production with error: {details => stuff failed, kind => bad-error}' }

    it 'passes validation' do
      is_expected.to run.with_params(deploy_status_good).and_return('error' => nil)
    end

    it 'fails a plan when a code deploy fails' do
      is_expected.to run.with_params(deploy_status_failed).and_return('error' => { 'message' => deploy_status_failed_message, 'code' => 'FailedCodeDeployment' })
    end
  end
end
