# frozen_string_literal: true

module Utils
  class << self
    # Check the existence of a specific shell command.
    #
    # @param [String] name
    #        The name of shell command.
    #
    # @return [Boolean]
    #         `true` for exist, `false` or else.
    #
    def command_exist?(name)
      system("command -v #{name} >/dev/null 2>&1")
    end

    def curl
      'curl'.tap do |s|
        raise "[ERROR] `#{s}` 命令不存在。" unless command_exist?(s)
      end
    end

    def wget
      'wget'.tap do |s|
        raise "[ERROR] `#{s}` 命令不存在。" unless command_exist?(s)
      end
    end

    def git
      'git'.tap do |s|
        raise "[ERROR] `#{s}` 命令不存在。" unless command_exist?(s)
      end
    end

    # Check whether the specified gem is installed.
    #
    # @param [String] gem_name
    #
    # @return [Boolean]
    #         `true` if installed; `false` otherwise.
    #
    def gem_installed?(gem_name)
      return false if gem_name.nil? || gem_name.empty?

      `gem list --installed #{gem_name}`.chomp.casecmp('true').zero?
    end

    def encode_uri_component(str)
      require 'uri'

      if URI.respond_to?(:encode_uri_component)
        URI.encode_uri_component(str)
      else
        URI.encode_www_form_component(str).gsub('+', '%20')
      end
    end

    def decode_uri_component(str)
      require 'uri'

      if URI.respond_to?(:decode_uri_component)
        URI.decode_uri_component(str)
      else
        # NOTE: No need to do `str.gsub('%20', '+')` firstly
        URI.decode_www_form_component(str)
      end
    end

    # Get specified App version string
    #
    # @param [String] name App name
    # @return [String] App version string
    #
    # @note https://stackoverflow.com/questions/27595435/how-to-return-app-version-in-terminal-on-osx
    def app_version(name, verbose: false)
      raise ArgumentError, "Invalid argument name: `#{name}`" unless name.is_a?(String) && !name.strip.empty?

      puts "[INFO][#{__method__}] App name: `#{name}`" if verbose

      info_plist_path = if name.end_with?('.app')
                          "/Applications/#{name}/Contents/Info.plist"
                        else
                          "/Applications/#{name}.app/Contents/Info.plist"
                        end
      raise "Cannot find the Info.plist file for `#{name}`" unless File.exist?(info_plist_path)

      puts "[INFO][#{__method__}] Info.plis filepath: `#{info_plist_path}`" if verbose

      if command_exist?('defaults')
        return `defaults read '#{info_plist_path}' CFBundleShortVersionString`.chomp
      else
        puts "[INFO][#{__method__}] Cannot find command `defaults`" if verbose
      end

      if File.exist?('/usr/libexec/PlistBuddy')
        return `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' '#{info_plist_path}'`.chomp
      else
        puts "[INFO][#{__method__}] Cannot find command `/usr/libexec/PlistBuddy`" if verbose
      end

      if command_exist?('plutil')
        return `plutil -extract CFBundleShortVersionString raw -o - '#{info_plist_path}'`.chomp
      else
        puts "[INFO][#{__method__}] Cannot find command `plutil`" if verbose
      end

      if command_exist?('mdls')
        raw_res = `mdls -name kMDItemVersion '#{info_plist_path.delete_suffix('/Contents/Info.plist')}'`
                    .chomp
                    .split('=')
                    .map(&:strip)
        return raw_res[1] if raw_res.size == 2 && raw_res[0] == 'kMDItemVersion'
      else
        puts "[INFO][#{__method__}] Cannot find command `mdls`" if verbose
      end

      raise "Fail to get version for `#{name}`."
    end
  end
end
