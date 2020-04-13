require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))

include RspecPuppetFacts

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

default_fact_files = [
  File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml')),
  File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml')),
]

default_fact_files.each do |f|
  next unless File.exist?(f) && File.readable?(f) && File.size?(f)

  begin
    default_facts.merge!(YAML.safe_load(File.read(f), [], [], true))
  rescue => e
    RSpec.configuration.reporter.message "WARNING: Unable to load #{f}: #{e}"
  end
end

# read default_facts and merge them over what is provided by facterdb
default_facts.each do |fact, value|
  add_custom_fact fact, value
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.mock_with :rspec
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
  end
  c.filter_run_excluding(bolt: true) unless ENV['GEM_BOLT']
  c.after(:suite) do
  end
end

# Ensures that a module is defined
# @param module_name Name of the module
def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module, false)
    last_module.const_get(next_module, false)
  end
end

RSpec.shared_context 'deployment' do
  let(:test_host) { 'http://puppet.test' }
  let(:deployment_owner) { 'ccaum' }
  let(:deployment_id) { '123' }
  let(:deployment_token) { '1234abcd' }
  let(:node_group_id) { 'aasdf-1234asdf-1234' }
  let(:environment_name) { 'development' }
  let(:control_repo) { 'test_control_repo' }
  let(:commit) { 'ef424ec352d4bc93317be901877e32f3c6a0289c' }
  let(:git_branch) { 'src_development' }
  let(:ajax_url) { "#{test_host}/#{deployment_owner}/ajax" }
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
    ENV['DEPLOYMENT_TOKEN'] = deployment_token
    ENV['WEB_UI_ENDPOINT'] = test_host
    ENV['REPO_TARGET_BRANCH'] = environment_name
    ENV['COMMIT'] = commit
    ENV['CONTROL_REPO'] = control_repo
    ENV['NODE_GROUP_ID'] = node_group_id
  end
end

# 'spec_overrides' from sync.yml will appear below this line
