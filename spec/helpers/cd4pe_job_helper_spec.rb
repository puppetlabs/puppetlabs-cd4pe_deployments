require 'open3'
require_relative '../../lib/puppet_x/puppetlabs/cd4pe_job_helper.rb'

describe 'cd4pe_job_helper' do
  before(:each) do
    @working_dir = File.join(Dir.getwd, "test_working_dir")
    Dir.mkdir(@working_dir)
  end

  after(:each) do
    FileUtils.remove_dir(@working_dir)
    $stdout = STDOUT
  end

  describe 'cd4pe_job_helper::initialize' do
    it 'Converts the docker run args into a usable string.' do
      arg1 = '--testarg=woot'
      arg2 = '--otherarg=hello'
      arg3 = '--whatever=isclever'
      user_specified_docker_run_args = [arg1, arg2, arg3]
  
      job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir, docker_run_args: user_specified_docker_run_args)
  
      expect(job_helper.docker_run_args).to eq("#{arg1} #{arg2} #{arg3}")
    end
  end

  describe 'cd4pe_job_helper::set_job_env_vars' do
    it 'Sets the job environment params.' do
      job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir)
  
      cd4pe_web_ui_endpoint = 'https://testtest.com'
      cd4pe_token = 'alksjdbhfnadhsbf'
      cd4pe_job_owner = 'carls cool carl'
      job_instance_id = '17'
  
      params = {
        'cd4pe_web_ui_endpoint' => cd4pe_web_ui_endpoint,
        'cd4pe_token' => cd4pe_token,
        'cd4pe_job_owner' => cd4pe_job_owner,
        'job_instance_id' => job_instance_id,
      }
  
      job_helper.set_job_env_vars(params)
      
      expect(ENV['WEB_UI_ENDPOINT']).to eq(cd4pe_web_ui_endpoint)
      expect(ENV['JOB_TOKEN']).to eq(cd4pe_token)
      expect(ENV['JOB_OWNER']).to eq(cd4pe_job_owner)
      expect(ENV['JOB_INSTANCE_ID']).to eq(job_instance_id)
    end
  
    it 'Sets the user-specified environment params.' do
      job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir)
  
      user_specified_env_vars = [
        'TEST_VAR_ONE=hello!', 
        'TEXT_VAR_TWO=yellow-bird', 
        'TEST_VAR_THREE=carl'
      ]
  
      params = { 'env_vars' => user_specified_env_vars }
  
      job_helper.set_job_env_vars(params)
      
      expect(ENV['TEST_VAR_ONE']).to eq('hello!')
      expect(ENV['TEXT_VAR_TWO']).to eq('yellow-bird')
      expect(ENV['TEST_VAR_THREE']).to eq('carl')
    end
  end

  describe 'cd4pe_job_helper::make_working_dir' do
    it 'Makes working directory as specified.' do
      job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir)
  
      # validate dir does not exist
      test_dir = File.join(@working_dir, 'test_dir')
      expect(File.exists?(test_dir)).to be(false)
  
      # create dir and validate it exists
      job_helper.make_working_dir(test_dir)
      expect(File.exists?(test_dir)).to be(true)
  
      # attempt to create again to validate it does not throw
      job_helper.make_working_dir(test_dir)
    end
  end

  describe 'cd4pe_job_helper::get_docker_run_cmd' do
    it 'Generates the correct docker run command.' do
      test_manifest_type = "AFTER_JOB_SUCCESS"
      test_docker_image = 'puppetlabs/test:10.0.1'
      arg1 = '--testarg=woot'
      arg2 = '--otherarg=hello'
      arg3 = '--whatever=doesntmatter'
      user_specified_docker_run_args = [arg1, arg2, arg3]
  
      job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir, docker_image: test_docker_image, docker_run_args: user_specified_docker_run_args)
  
      docker_run_command = job_helper.get_docker_run_cmd(test_manifest_type)
      cmd_parts = docker_run_command.split(' ')
  
      expect(cmd_parts[0]).to eq('docker')
      expect(cmd_parts[1]).to eq('run')
      expect(cmd_parts[2]).to eq(arg1)
      expect(cmd_parts[3]).to eq(arg2)
      expect(cmd_parts[4]).to eq(arg3)
      expect(cmd_parts[5]).to eq('-v')
      expect(cmd_parts[6].end_with?("/#{File.basename(@working_dir)}/cd4pe_job/repo:/repo")).to be(true)
      expect(cmd_parts[7]).to eq('-v')
      expect(cmd_parts[8].end_with?("/#{File.basename(@working_dir)}/cd4pe_job/jobs/unix:/cd4pe_job")).to be(true)
      expect(cmd_parts[9]).to eq(test_docker_image)
      expect(cmd_parts[10]).to eq('/cd4pe_job/AFTER_JOB_SUCCESS')
    end
  end
end

describe 'cd4pe_job_helper::run_job' do

  before(:all) do
    @working_dir = File.join(Dir.getwd, "test_working_dir")
    cd4pe_job_dir = File.join(@working_dir, 'cd4pe_job')
    jobs_dir = File.join(cd4pe_job_dir, 'jobs')
    unix_dir = File.join(jobs_dir, 'unix')
    @job_script = File.join(unix_dir, 'JOB')
    @after_job_success_script = File.join(unix_dir, 'AFTER_JOB_SUCCESS')
    @after_job_failure_script = File.join(unix_dir, 'AFTER_JOB_FAILURE')

    Dir.mkdir(@working_dir)
    Dir.mkdir(cd4pe_job_dir)
    Dir.mkdir(jobs_dir)
    Dir.mkdir(unix_dir)

    File.write(@job_script, '')
    File.chmod(0775, @job_script)
    File.write(@after_job_success_script, '')
    File.chmod(0775, @after_job_success_script)
    File.write(@after_job_failure_script, '')
    File.chmod(0775, @after_job_failure_script)
  end

  after(:all) do
    FileUtils.remove_dir(@working_dir)
  end

  it 'Runs the success script after a successful script run' do
    $stdout = StringIO.new

    expected_output = 'in job script'
    after_job_success_message = 'in after success script'

    File.write(@job_script, "echo #{expected_output}")
    File.write(@after_job_success_script, "echo #{after_job_success_message}")

    job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir)
    output = job_helper.run_job

    expect(output[:job][:exit_code]).to eq(0)
    expect(output[:job][:message]).to eq("#{expected_output}\n")
    expect(output[:after_job_success][:exit_code]).to eq(0)
    expect(output[:after_job_success][:message]).to eq("#{after_job_success_message}\n")

  end

  it 'Runs the failure script after a failed script run' do
    $stdout = StringIO.new

    expected_output = 'this gonna fail'
    after_job_failure_message = 'in after failure script'
    File.write(@job_script, expected_output)
    File.write(@after_job_failure_script, "echo #{after_job_failure_message}")

    job_helper = PuppetX::Puppetlabs::CD4PEJobHelper.new(working_dir: @working_dir)
    output = job_helper.run_job

    expect(output[:job][:exit_code]).to eq(127)
    expect(output[:job][:message].end_with?("command not found\n")).to be(true)
    expect(output[:after_job_failure][:exit_code]).to eq(0)
    expect(output[:after_job_failure][:message]).to eq("#{after_job_failure_message}\n")
  end

end