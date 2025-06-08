# frozen_string_literal: true

# Utility methods for release tasks - build and deploy
module ReleaseTaskUtils
  def self.parse_build_args # rubocop:disable Metrics/MethodLength
    parsed = {}.with_indifferent_access
    ARGV.each do |arg|
      case arg
      when '--no-tests'
        parsed[:run_tests] = false
      when '--dry-run'
        parsed[:dry_run] = true
      else
        raise ArgumentError "Unknown argument:' #{arg}'. Valid arguments are: --no-tests, --dry-run'"
      end
    end
    parsed
  end

  def self.parse_deploy_args # rubocop:disable Metrics/MethodLength
    parsed = {}.with_indifferent_access
    ARGV.each do |arg|
      case arg
      when '--dry-run'
        parsed[:dry_run] = true
      when /\A.*\d+\.\d+\.\d+\z/.match(arg)
        parsed[:tag] = arg
      else
        raise ArgumentError "Unknown argument:' #{arg}'. Valid arguments are:  '--dry-run'" \
                              ", a version tag matching /\A.*\d+\.\d+\.\d+\z/"
      end
    end
    parsed
  end
end
