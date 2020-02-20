#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'rubygems/package'
require 'open3'

@params = JSON.parse(STDIN.read)
require_relative File.join(@params['_installdir'], 'cd4pe_deployments', 'lib', 'puppet_x', 'puppetlabs', 'cd4pe_client')
require_relative File.join(@params['_installdir'], 'cd4pe_deployments', 'lib', 'puppet_x', 'puppetlabs', 'gzip_helper')
require_relative File.join(@params['_installdir'], 'cd4pe_deployments', 'lib', 'puppet_x', 'puppetlabs', 'cd4pe_job_helper')

@working_dir = File.join(@params['_installdir'], 'cd4pe_job_working_dir')

def docker_image
  @params['docker_image']
end

def docker_run_args
  @params["docker_run_args"]
end

begin
  job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir, docker_image: docker_image, docker_run_args: docker_run_args)
  job_helper.set_job_env_vars(@params)
  job_helper.make_working_dir(@working_dir)
  zipped_file = job_helper.get_job_script_and_control_repo
  PuppetX::Puppetlabs::GZipHelper.unzip(zipped_file, @working_dir)
  exit_code = job_helper.run_job

  exit exit_code
rescue => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end