require 'zlib'

module PuppetX::Puppetlabs
  # A static class to unzip .tar.gz files
  class GZipHelper

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
end
