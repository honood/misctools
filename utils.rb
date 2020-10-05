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

    # Check whether the specified gem is installed.
    #
    # @param [String] gem_name
    #
    # @return [Boolean]
    #         `true` if installed; `false` otherwise.
    #
    def gem_installed?(gem_name)
      return false if gem_name.nil? || gem_name.empty?

      `gem list --installed #{gem_name}`.chomp.downcase == 'true'
    end
  end
end
