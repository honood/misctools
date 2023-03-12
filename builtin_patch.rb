# frozen_string_literal: true

class String
  if method_defined?(:delete_cxx_comments)
    raise '`String#delete_cxx_comments` is already defined elsewhere.'
  end

  # Delete C++-style comments from code string
  # https://en.cppreference.com/w/cpp/comment
  #
  # @todo 1. make line separator can be specified
  # @todo 2. make user can decide to keep the line separator in comments or not
  # @todo 3. use more performance algorithm instead of `gsub`
  def delete_cxx_comments
    gsub(%r{/\*.*?\*/}m) { "\n" * ::Regexp.last_match(0).count("\n") }.gsub(%r{//.*?\n}, "\n")
  end
end

require 'pathname'
class Pathname
  if method_defined?(:readlines_no_cxx_comments)
    raise '`Pathname#readlines_no_cxx_comments` is already defined elsewhere.'
  end

  def readlines_no_cxx_comments
    read(encoding: Encoding::UTF_8).delete_cxx_comments.lines
  end
end
