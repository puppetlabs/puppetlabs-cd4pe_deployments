require 'puppet'
# This file was copied from https://github.com/puppetlabs/puppetlabs-peadm/blob/master/spec/spec_helper_local.rb
if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
  begin
    require 'bolt_spec/plans'
    BoltSpec::Plans.init

    # Seems to be needed to make `run_plan` available inside examples:
    RSpec.configure { |c| c.include BoltSpec::Plans }
  rescue LoadError => e
    warn e.message
    warn '=== bolt tests will not run; ensure bolt gem is installed (requires Puppet 6+)'
  end
end

RSpec.shared_context 'deployment' do
  let(:test_host) { 'http://puppet.test' }
  let(:deployment_owner) { 'ccaum' }
  let(:deployment_id) { '123' }
  let(:deployment_domain) { 'd25' }
  let(:deployment_token) { '1234abcd' }
  let(:node_group_id) { 'aasdf-1234asdf-1234' }
  let(:environment_name) { 'development' }
  let(:control_repo) { 'test_control_repo' }
  let(:commit) { 'ef424ec352d4bc93317be901877e32f3c6a0289c' }
  let(:git_branch) { 'src_development' }
  let(:ajax_url) { "#{test_host}/#{deployment_owner}/ajax" }
  let(:api_v1_path) { "#{test_host}/api/v1" }
  let(:response) do
    {
      'result' => {
        'name' => 'deployment',
        'id' => '123',
        'description' => 'carls cool deployment',
      },
      'error' => nil,
    }
  end

  let(:error_response) do
    {
      'result' => nil,
      'error' => {
        'message' => 'Some error message',
        'code' => 'ErrorCode',
      },
    }
  end

  before(:each) do
    ENV['DEPLOYMENT_OWNER'] = deployment_owner
    ENV['DEPLOYMENT_ID'] = deployment_id
    ENV['DEPLOYMENT_DOMAIN'] = deployment_domain
    ENV['DEPLOYMENT_TOKEN'] = deployment_token
    ENV['WEB_UI_ENDPOINT'] = test_host
    ENV['REPO_TARGET_BRANCH'] = environment_name
    ENV['COMMIT'] = commit
    ENV['CONTROL_REPO'] = control_repo
    ENV['NODE_GROUP_ID'] = node_group_id
  end
end
