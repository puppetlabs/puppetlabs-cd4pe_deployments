require 'open3'
require 'puppet_x'
require 'rubygems/package'
require_relative '../../lib/puppet_x/puppetlabs/gzip_helper.rb'

#
# All tests in require the usage of static gzip test files
# located in: cd4pe_deployments/spec/fixtures/test_tar_files
#

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
    PuppetX::Puppetlabs::GZipHelper.unzip(single_file_tar, @working_dir)

    expect(File.exists?(single_file)).to be(true)

    file_data =  File.read(single_file)
    expect(file_data).to eql('test data')
  end

  it 'unzips a single level directory tar.gz' do
    single_level_dir_tar = File.join(@test_tar_files_dir, 'gzipSingleLevelDirectoryTest.tar.gz')
    single_level_dir = File.join(@working_dir, 'gzipSingleLevelDirectoryTest')
    PuppetX::Puppetlabs::GZipHelper.unzip(single_level_dir_tar, @working_dir)

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
    PuppetX::Puppetlabs::GZipHelper.unzip(multi_level_dir_tar, @working_dir)

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
    PuppetX::Puppetlabs::GZipHelper.unzip(executable_tar, @working_dir)

    output = ''
    exit_code = 0
  
    Open3.popen2e(executable) do |stdin, stdout_stderr, wait_thr|
      exit_code = wait_thr.value.exitstatus
      output = stdout_stderr.read
    end

    expect(exit_code).to eql(0)
    expect(output).to eql("hello!\n")
  end

end