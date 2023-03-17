# frozen_string_literal: true

require 'bigdecimal'
# When you require `bigdecimal/util`, the `to_d` method will be
# available on BigDecimal and the native Integer, Float, Rational,
# and String classes.
#
# https://ruby-doc.org/3.2.1/exts/bigdecimal/BigDecimal.html#class-BigDecimal-label-bigdecimal-2Futil
require 'bigdecimal/util'

require 'pathname'

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

  if method_defined?(:to_percentage)
    raise '`String#to_percentage` is already defined elsewhere.'
  end

  # @note You will not get result as expected by the following implementation:
  #
  #   def to_percentage
  #     "#{to_f * 100}%"
  #   end
  #
  # For example, `"0.612".to_percentage` will give you `"61.199999999999996%"`,
  # rather than `"61.2%"`.
  def to_percentage
    # https://ruby-doc.org/3.2.1/exts/bigdecimal/Kernel.html#method-i-BigDecimal
    bd = BigDecimal(self, exception: false)
    raise ArgumentError, %(cannot convert `"#{self}"` to percentage) if bd.nil?

    "#{(bd * 100).to_s('F')}%"
  end
end

class Pathname
  if method_defined?(:readlines_no_cxx_comments)
    raise '`Pathname#readlines_no_cxx_comments` is already defined elsewhere.'
  end

  def readlines_no_cxx_comments
    read(encoding: Encoding::UTF_8).delete_cxx_comments.lines
  end
end

class Float
  if method_defined?(:to_percentage)
    raise '`Float#to_percentage` is already defined elsewhere.'
  end

  # @note You will not get result as expected by the following implementation:
  #
  #   def to_percentage
  #     "#{self * 100}%"
  #   end
  #
  # For example, `0.612.to_percentage` will give you `"61.199999999999996%"`,
  # rather than `"61.2%"`.
  def to_percentage
    # https://ruby-doc.org/3.2.1/exts/bigdecimal/Kernel.html#method-i-BigDecimal
    bd = BigDecimal(self, 0, exception: false)
    raise ArgumentError, %(cannot convert `#{self}` to percentage) if bd.nil?

    "#{(bd * 100).to_s('F')}%"
  end
end

class Integer
  if method_defined?(:to_percentage)
    raise '`Integer#to_percentage` is already defined elsewhere.'
  end

  def to_percentage
    "#{self * 100}%"
  end
end
