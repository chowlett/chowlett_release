# frozen_string_literal: true

# The following line, created by RubyMine "File/New/Project/Gem",  attracts a RubyMine inspection warning
# "Expected non-nillable type":
#   $LOAD_PATH.unshift File.expand_path('../lib', __dir__)
# This is the only way I could find to eliminate the warning. The root cause of the warning is that
# __dir__ can return nil. The intermediate variable is needed because `__dir__ is a method,
# not a constant, so the inspection can't assume that it is not nil in a call that follows
# a call that returned non-nil. This method cannot be assumed to be idempotent in this respect.
# Note: __dir__ returns nil iff __FILE__ is nil. This is rare but can happen in some obscure circumstances -
# for example, when the containing code is interpreted with "eval".

relative_to = __dir__
$LOAD_PATH.unshift File.expand_path('../lib', relative_to) unless relative_to.nil?

require 'strongstart_release'
require 'minitest/autorun'
