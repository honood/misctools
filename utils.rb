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
  end
end
