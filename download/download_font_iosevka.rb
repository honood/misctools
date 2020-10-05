# frozen_string_literal: true

require 'octokit'
require 'netrc'
require 'optparse'
require 'fileutils'
require 'parallel'

module Download
  module Be5invisIosevka
    REPO = 'be5invis/Iosevka'

    module_function

    def netrc_exist?
      user, pass = Netrc.read['api.github.com']
      !(pass.nil? || pass.empty? || user.nil? || user.empty?)
    end

    def tag_and_dir
      opt_tag = nil
      opt_dir = nil
      OptionParser.new do |opts|
        opts.banner = <<~BANNER
          Usage: #{File.basename(__FILE__)} [options] [arguments]

          NOTE: 
              1. If you do not like to use the `--tag` option to specify a tag, you
                 can also give a argument to do the same. The following two usages  
                 are equivalent;
              2. If you neither provide `--tag` option nor any arguments, the latest 
                 release will be downloaded. 

        BANNER

        opts.on('-h', '--help', 'Print this help message.') do
          puts opts
          exit
        end

        opts.on('-tTAG', '--tag=TAG', 'Specified tag to download, like `v3.6.3`.') do |t|
          opt_tag = t
        end

        opts.on('-dDIR', '--dir=DIR', 'Specified a local directory to save files.') do |d|
          opt_dir = d
        end
      end.parse!

      arg_tag = ARGV[0]

      [opt_tag || arg_tag, opt_dir]
    end

    def download
      client = if netrc_exist?
                 Octokit::Client.new(:netrc => true)
               else
                 Octokit::Client.new
               end

      tag, dir = tag_and_dir
      release = if tag.nil? || tag.empty?
                  client.latest_release(REPO)
                else
                  client.release_for_tag(REPO, tag)
                end

      download_release_name = release[:name] || release[:tag_name]
      is_prerelease = release[:prerelease]
      download_urls = release[:assets]
                        .select { |asset| asset[:name].start_with?('pkg-') }
                        .map { |asset| asset[:browser_download_url] }
                        .compact

      puts "[WARN] `#{download_release_name}` is a prerelease." if is_prerelease

      if download_urls.nil? || download_urls.empty?
        puts "[WARN] No downloads available for `#{download_release_name}`."
        exit
      end

      download_dir = if dir.nil? || dir.empty?
                       File.join(Dir.pwd, download_release_name)
                     else
                       File.join(File.expand_path(dir), download_release_name)
                     end
      FileUtils.rm_rf(download_dir) if Dir.exist?(download_dir)
      FileUtils.mkdir_p(download_dir)

      file_count = download_urls.size
      puts "[INFO] `#{file_count}` files will be downloaded into `#{download_dir}`:\n\n"

      Dir.chdir(download_dir) do
        Parallel.each_with_index(download_urls, in_processes: 5) do |download_url, index|
          download_cmd = <<~CMD
            curl -fsSLO #{download_url}
          CMD

          puts %([INFO] [#{index + 1}/#{file_count}] begin downloading: #{download_url})
          `#{download_cmd}`
          FileUtils.chmod('a=r', File.basename(download_url))
          puts %([INFO] [#{index + 1}/#{file_count}] finish downloading: #{download_url})
        end

        puts "\n[INFO] `#{Dir.children('.').size}/#{file_count}` files have been downloaded into `#{download_dir}`."
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Download::Be5invisIosevka.download
end
