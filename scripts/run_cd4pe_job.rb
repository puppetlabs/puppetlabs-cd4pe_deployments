#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'rubygems/package'
require 'open3'

# In order for this script to be executed via the Puppet Bolt 'run_script' command, 
# we need all relevant classes to be in a single file.

class Logger < Object
  # Class to track logs + timestamps. To be returned as part of the Bolt log output
  def initialize()
    @logs = []
  end

  def log(log)
    @logs.push({ timestamp: Time.now.getutc, message: log})
  end

  def get_logs
    @logs
  end
end

class GZipHelper
  # static class to decompress tar.gz files
  TAR_LONGLINK = '././@LongLink'.freeze
  SYMLINK_SYMBOL = '2'.freeze

  def self.unzip(zipped_file_path, destination_path)
    # helper functions
    def self.make_dir(entry, dest)
      FileUtils.rm_rf(dest) unless File.directory?(dest)
      FileUtils.mkdir_p(dest, :mode => entry.header.mode, :verbose => false)
    end

    def self.make_file(entry, dest)
      FileUtils.rm_rf dest unless File.file? dest
      File.open(dest, "wb") do |file|
        file.print(entry.read)
      end
      FileUtils.chmod(entry.header.mode, dest, :verbose => false)
    end

    def self.preserve_symlink(entry, dest)
      File.symlink(entry.header.linkname, dest)
    end

    # Unzip tar.gz
    Gem::Package::TarReader.new( Zlib::GzipReader.open zipped_file_path ) do |tar|
      dest = nil
      tar.each do |entry|

        # If file/dir name length > 100 chars, its broken into multiple entries.
        # This code glues the name back together
        if entry.full_name == TAR_LONGLINK
          dest = File.join(destination_path, entry.read.strip)
          next
        end

        # If the destination has not yet been set
        # set it equal to the path + file/dir name
        if (dest.nil?)
          dest = File.join(destination_path, entry.full_name)
        end

        # Write the file or dir
        if entry.directory?
          self.make_dir(entry, dest)
        elsif entry.file?
          self.make_file(entry, dest)
        elsif entry.header.typeflag == SYMLINK_SYMBOL
          self.preserve_symlink(entry, dest)
        end

        # reset dest for next entry iteration
        dest = nil
      end
    end
  end
end

class CD4PEJobRunner < Object
  # Class for downloading, running, and logging CD4PE jobs
  attr_reader :docker_run_args 

  MANIFEST_TYPE = { 
    :JOB => "JOB", 
    :AFTER_JOB_SUCCESS => "AFTER_JOB_SUCCESS", 
    :AFTER_JOB_FAILURE => "AFTER_JOB_FAILURE" }

  def initialize(working_dir:, job_token:, web_ui_endpoint:, job_owner:, job_instance_id:, logger:, docker_image: nil, docker_run_args: nil)
    @working_dir = working_dir
    @job_token = job_token
    @web_ui_endpoint = web_ui_endpoint
    @job_owner = job_owner
    @job_instance_id = job_instance_id
    @docker_image = docker_image
    @docker_run_args = docker_run_args
    @docker_based_job = !blank?(docker_image)

    @logger = logger

    @local_jobs_dir = File.join(@working_dir, "cd4pe_job", "jobs", "unix")
    @local_repo_dir = File.join(@working_dir, "cd4pe_job", "repo")
  end

  def get_job_script_and_control_repo
    @logger.log("Downloading job scripts and control repo from CD4PE.")
    target_file = File.join(@working_dir, "cd4pe_job.tar.gz")

    api_endpoint = File.join(@web_ui_endpoint, @job_owner, 'getJobScriptAndControlRepo')
    curl_command = "curl -o #{target_file} -H 'Content-Type: application/json' -H 'Authorization: Bearer token #{@job_token}' -v '#{api_endpoint}?jobInstanceId=#{@job_instance_id}'"
    result = run_system_cmd(curl_command)

    if (result[:exit_code] != 0)
      @logger.log("Failed to download paylod from CD4PE.")
      @logger.log("curl command failed with exit code: #{result[:exit_code]} and message:\n#{result[:message]}")
    end

    begin
      @logger.log("Unzipping #{target_file} to #{@working_dir}")
      GZipHelper.unzip(target_file, @working_dir)
    rescue => e
      error = "Failed to decompress CD4PE repo/script payload. This can occur if the downloaded file is not in gzip format, or if the endpoint hit returned nothing. Error: #{e.message}"
      raise error
    end

    target_file
  end

  def run_job
    @logger.log("Running job instance #{@job_instance_id}.")

    result = execute_manifest(MANIFEST_TYPE[:JOB])
    combined_result = {}
    if (result[:exit_code] == 0)
      combined_result = on_job_complete(result, MANIFEST_TYPE[:AFTER_JOB_SUCCESS])
    else
      combined_result = on_job_complete(result, MANIFEST_TYPE[:AFTER_JOB_FAILURE])
    end

    @logger.log("Job instance #{@job_instance_id} run complete.")
    combined_result
  end

  def on_job_complete(result, next_manifest_type)
    output = {}
    output[:job] = {
      exit_code: result[:exit_code], 
      message: result[:message]
    }
  
    # if a AFTER_JOB_SUCCESS or AFTER_JOB_FAILURE script exists, run it now!
    run_followup_script = File.exists?(File.join(@local_jobs_dir, next_manifest_type))
    if (run_followup_script)
      @logger.log("#{next_manifest_type} script specified.")
      followup_script_result = execute_manifest(next_manifest_type)
      output[next_manifest_type.downcase.to_sym] = {
        exit_code: followup_script_result[:exit_code], 
        message: followup_script_result[:message]
      }
    end

    output
  end

  def execute_manifest(manifest_type)
    @logger.log("Executing #{manifest_type} manifest.")
    result = {}
    if (@docker_based_job)
      @logger.log("Docker image specified. Running #{manifest_type} manifest on docker image: #{@docker_image}.")
      result = run_with_docker(manifest_type)
    else
      @logger.log("No docker image specified. Running #{manifest_type} manifest directly on machine.")
      result = run_with_system(manifest_type)
    end
    
    if (result[:exit_code] == 0)
      @logger.log("#{manifest_type} succeeded!")
    else 
      @logger.log("#{manifest_type} failed with exit code: #{result[:exit_code]}: #{result[:message]}")
    end
    result
  end
  
  def run_with_system(manifest_type)
    local_job_script = File.join(@local_jobs_dir, manifest_type)
    run_system_cmd(local_job_script)
  end

  def get_docker_run_cmd(manifest_type)
    repo_volume_mount = "#{@local_repo_dir}:/repo"
    scripts_volume_mount = "#{@local_jobs_dir}:/cd4pe_job"
    docker_bash_script = "/cd4pe_job/#{manifest_type}"
    "docker run #{@docker_run_args} -v #{repo_volume_mount} -v #{scripts_volume_mount} #{@docker_image} #{docker_bash_script}"
  end
  
  def run_with_docker(manifest_type)
    docker_cmd = get_docker_run_cmd(manifest_type)
    run_system_cmd(docker_cmd)
  end
  
  def run_system_cmd(cmd)
    output = ''
    exit_code = 0
    @logger.log("Executing system command: #{cmd}")
    Open3.popen2e(cmd) do |stdin, stdout_stderr, wait_thr|
      exit_code = wait_thr.value.exitstatus
      output = stdout_stderr.read
    end
  
    { :exit_code => exit_code, :message => output }
  end

  def blank?(str)
    str.nil? || str.empty?
  end
end

def parse_args(argv)
  params = {}
  argv.each do |arg|
    split = arg.split("=", 2) # split on first instance of '='
    key = split[0]
    value = split[1]
    params[key] = value
  end
  params
end

def get_combined_exit_code(output)
  job = output[:job]
  after_job_success = output[:after_job_success]
  after_job_failure = output[:after_job_failure]

  exit_code_sum = job[:exit_code]
  if (!after_job_success.nil?)
    exit_code_sum = exit_code_sum + after_job_success[:exit_code]
  end

  if (!after_job_failure.nil?)
    exit_code_sum = exit_code_sum + after_job_failure[:exit_code]
  end

  exit_code_sum == 0 ? 0 : 1
end

def set_job_env_vars(task_params)
  @logger.log("Setting user-specified job environment vars.")
  env_var_string = task_params['env_vars']
  if (!env_var_string.nil?)
    user_specified_env_vars = env_var_string.split("\n")
    user_specified_env_vars.each do |var|
      pair = var.split("=")
      key = pair[0]
      value = pair[1]
      ENV[key] = value
    end
  end
end

def make_working_dir(working_dir)
  @logger.log("Creating working directory #{working_dir}.")
  Dir.mkdir(working_dir) unless File.exists?(working_dir)
end

if __FILE__ == $0 # This block will only be invoked if this file is executed. Will NOT execute when 'required' (ie. for testing the contained classes)
  @logger = Logger.new
  begin
    params = parse_args(ARGV)
    working_dir = File.join(Dir.pwd, 'cd4pe_job_working_dir')

    docker_image = params['docker_image']
    docker_run_args = params["docker_run_args"]
    job_instance_id = params["job_instance_id"]
    web_ui_endpoint = params['cd4pe_web_ui_endpoint']
    job_token = params['cd4pe_token']
    job_owner = params['cd4pe_job_owner']

    set_job_env_vars(params)
    make_working_dir(working_dir)

    job_runner = CD4PEJobRunner.new(working_dir: working_dir, docker_image: docker_image, docker_run_args: docker_run_args, job_token: job_token, web_ui_endpoint: web_ui_endpoint, job_owner: job_owner, job_instance_id: job_instance_id, logger: @logger)
    job_runner.get_job_script_and_control_repo
    output = job_runner.run_job

    output[:logs] = @logger.get_logs
    puts output.to_json

    exit get_combined_exit_code(output)
  rescue => e
    @logger.log(e.message)
    puts({ status: 'failure', error: e.message, logs: @logger.get_logs }.to_json)
    exit 1
  end
end
