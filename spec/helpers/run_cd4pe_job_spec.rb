require 'open3'
require_relative '../../scripts/run_cd4pe_job.rb'

describe 'run_cd4pe_job' do
  before(:all) do 
    @logger = Logger.new
  end

  before(:each) do
    @working_dir = File.join(Dir.getwd, "test_working_dir")
    Dir.mkdir(@working_dir)

    @web_ui_endpoint = 'https://testtest.com'
    @job_token = 'alksjdbhfnadhsbf'
    @job_owner = 'carls cool carl'
    @job_instance_id = '17'
  end

  after(:each) do
    FileUtils.remove_dir(@working_dir)
    $stdout = STDOUT
  end

  describe 'set_job_env_vars' do
    it 'Sets the user-specified environment params.' do
      user_specified_env_vars = "TEST_VAR_ONE=hello!\nTEXT_VAR_TWO=yellow-bird\nTEST_VAR_THREE=carl"

      params = { 'env_vars' => user_specified_env_vars }

      set_job_env_vars(params)
      
      expect(ENV['TEST_VAR_ONE']).to eq('hello!')
      expect(ENV['TEXT_VAR_TWO']).to eq('yellow-bird')
      expect(ENV['TEST_VAR_THREE']).to eq('carl')
    end
  end

  describe 'make_working_dir' do
    it 'Makes working directory as specified.' do
      # validate dir does not exist
      test_dir = File.join(@working_dir, 'test_dir')
      expect(File.exists?(test_dir)).to be(false)

      # create dir and validate it exists
      make_working_dir(test_dir)
      expect(File.exists?(test_dir)).to be(true)

      # attempt to create again to validate it does not throw
      make_working_dir(test_dir)
    end
  end

  describe 'get_combined_exit_code' do
    it ('should be 0 if job and after_job_success are 0') do
      output = { job: { exit_code: 0}, after_job_success: { exit_code: 0} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(0)
    end

    it ('should be 1 if job or after_job_success are not 0') do
      output = { job: { exit_code: 1}, after_job_success: { exit_code: 0} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 125}, after_job_success: { exit_code: 0} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 0}, after_job_success: { exit_code: 1} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 0}, after_job_success: { exit_code: 125} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 1}, after_job_success: { exit_code: 125} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)
    end

    it ('should be 1 if job or after_job_failure are not 0') do
      output = { job: { exit_code: 1}, after_job_failure: { exit_code: 0} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 125}, after_job_failure: { exit_code: 0} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 0}, after_job_failure: { exit_code: 1} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 0}, after_job_failure: { exit_code: 125} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)

      output = { job: { exit_code: 1}, after_job_failure: { exit_code: 125} }
      test_code = get_combined_exit_code(output)
      expect(test_code).to eq(1)
    end
  end

  describe 'parse_args' do
    it 'should parse args appropriately' do
      key1 = "key1"
      value1 = "value1"
      key2 = "key2"
      value2 = "value2"
      key3 = "key3"
      value3 = "value3"

      args = [
        "#{key1}=#{value1}",
        "#{key2}=#{value2}",
        "#{key3}=#{value3}",
      ]

      parsed_args = parse_args(args)

      expect(parsed_args[key1]).to eq(value1)
      expect(parsed_args[key2]).to eq(value2)
      expect(parsed_args[key3]).to eq(value3)
    end
  end

  describe 'cd4pe_job_helper::initialize' do
    it 'Passes the docker run args throug without modifying thhe structure.' do
      arg1 = '--testarg=woot'
      arg2 = '--otherarg=hello'
      arg3 = '--whatever=isclever'
      user_specified_docker_run_args = "#{arg1} #{arg2} #{arg3}"
  
      job_helper = CD4PEJobRunner.new(working_dir: @working_dir, docker_run_args: user_specified_docker_run_args, job_token: @job_token, web_ui_endpoint: @web_ui_endpoint, job_owner: @job_owner, job_instance_id: @job_instance_id, logger: @logger)
  
      expect(job_helper.docker_run_args).to eq("#{arg1} #{arg2} #{arg3}")
    end
  end

  describe 'cd4pe_job_helper::get_docker_run_cmd' do
    it 'Generates the correct docker run command.' do
      test_manifest_type = "AFTER_JOB_SUCCESS"
      test_docker_image = 'puppetlabs/test:10.0.1'
      arg1 = '--testarg=woot'
      arg2 = '--otherarg=hello'
      arg3 = '--whatever=doesntmatter'
      user_specified_docker_run_args = "#{arg1} #{arg2} #{arg3}"
  
      job_helper = CD4PEJobRunner.new(working_dir: @working_dir, docker_image: test_docker_image, docker_run_args: user_specified_docker_run_args, job_token: @job_token, web_ui_endpoint: @web_ui_endpoint, job_owner: @job_owner, job_instance_id: @job_instance_id, logger: @logger)
  
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
    @logger = Logger.new
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

    job_helper = CD4PEJobRunner.new(working_dir: @working_dir, job_token: @job_token, web_ui_endpoint: @web_ui_endpoint, job_owner: @job_owner, job_instance_id: @job_instance_id, logger: @logger)
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

    job_helper = CD4PEJobRunner.new(working_dir: @working_dir, job_token: @job_token, web_ui_endpoint: @web_ui_endpoint, job_owner: @job_owner, job_instance_id: @job_instance_id, logger: @logger)
    output = job_helper.run_job

    expect(output[:job][:exit_code]).to eq(127)
    expect(output[:job][:message].end_with?("command not found\n")).to be(true)
    expect(output[:after_job_failure][:exit_code]).to eq(0)
    expect(output[:after_job_failure][:message]).to eq("#{after_job_failure_message}\n")
  end
end


describe 'cd4pe_job_helper::unzip' do
  before(:all) do
    @working_dir = File.join(Dir.getwd, 'test_working_dir')
    @test_tar_files_dir = File.join(Dir.getwd, 'spec', 'fixtures', 'test_tar_files')
    Dir.mkdir(@working_dir)
  end

  after(:all) do
    FileUtils.remove_dir(@working_dir)
  end

  it 'unzips a single file tar.gz' do
    single_file_tar = File.join(@test_tar_files_dir, 'gzipSingleFileTest.tar.gz')
    single_file = File.join(@working_dir, 'gzipSingleFileTest')
    GZipHelper.unzip(single_file_tar, @working_dir)

    expect(File.exists?(single_file)).to be(true)

    file_data =  File.read(single_file)
    expect(file_data).to eql('test data')
  end

  it 'unzips a single level directory tar.gz' do
    single_level_dir_tar = File.join(@test_tar_files_dir, 'gzipSingleLevelDirectoryTest.tar.gz')
    single_level_dir = File.join(@working_dir, 'gzipSingleLevelDirectoryTest')
    GZipHelper.unzip(single_level_dir_tar, @working_dir)

    expect(File.exists?(single_level_dir)).to be(true)
    test_file_1 = File.join(single_level_dir, 'testFile1')
    test_file_2 = File.join(single_level_dir, 'testFile2')
    expect(File.exists?(test_file_1)).to be(true)
    expect(File.exists?(test_file_2)).to be(true)

    file_1_data =  File.read(test_file_1)
    file_2_data =  File.read(test_file_2)
    expect(file_1_data).to eql('I am test file 1!')
    expect(file_2_data).to eql('I am test file 2!')
  end

  it 'unzips a multi level directory tar.gz' do
    multi_level_dir_tar = File.join(@test_tar_files_dir, 'gzipMultiLevelDirectoryTest.tar.gz')
    multi_level_dir = File.join(@working_dir, 'gzipMultiLevelDirectoryTest')
    sub_dir = File.join(multi_level_dir, 'subDir')
    GZipHelper.unzip(multi_level_dir_tar, @working_dir)

    # root dir
    expect(File.exists?(multi_level_dir)).to be(true)
    root_file_1 = File.join(multi_level_dir, 'rootFile1')
    root_file_2 = File.join(multi_level_dir, 'rootFile2')
    expect(File.exists?(root_file_1)).to be(true)
    expect(File.exists?(root_file_2)).to be(true)

    root_file_1_data =  File.read(root_file_1)
    root_file_2_data =  File.read(root_file_2)
    expect(root_file_1_data).to eql('I am in root 1!')
    expect(root_file_2_data).to eql('I am in root 2!')

    # sub dir
    expect(File.exists?(sub_dir)).to be(true)
    sub_file_1 = File.join(sub_dir, 'subDirFile1')
    sub_file_2 = File.join(sub_dir, 'subDirFile2')
    expect(File.exists?(sub_file_1)).to be(true)
    expect(File.exists?(sub_file_2)).to be(true)

    sub_file_1_data =  File.read(sub_file_1)
    sub_file_2_data =  File.read(sub_file_2)
    expect(sub_file_1_data).to eql('I am in sub 1!')
    expect(sub_file_2_data).to eql('I am in sub 2!')
  end

  it 'maintains file permissions when extracting' do
    executable_tar = File.join(@test_tar_files_dir, 'executableFileTest.tar.gz')
    executable = File.join(@working_dir, 'executableFileTest')
    GZipHelper.unzip(executable_tar, @working_dir)

    output = ''
    exit_code = 0
  
    Open3.popen2e(executable) do |stdin, stdout_stderr, wait_thr|
      exit_code = wait_thr.value.exitstatus
      output = stdout_stderr.read
    end

    expect(exit_code).to eql(0)
    expect(output).to eql("hello!\n")
  end

  it 'unzips a file with a filename > 100 characters' do
    single_level_dir_tar = File.join(@test_tar_files_dir, 'long_file_name.tar.gz')
    single_level_dir = File.join(@working_dir, 'long_file_name')
    GZipHelper.unzip(single_level_dir_tar, @working_dir)

    expect(File.exists?(single_level_dir)).to be(true)
    test_file_1 = File.join(single_level_dir, 'IAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPERLONGFILENAMEIAMASUPE')
    expect(File.exists?(test_file_1)).to be(true)
  end

end