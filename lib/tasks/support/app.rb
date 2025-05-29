# frozen_string_literal: true

module App
  def self.app_name
    app_name = Rails.application.class.module_parent&.name&.downcase

    raise "Unable to determine the name of the enclosing app." if app_name.nil? || app_name.empty?
    raise "Unexpected app name '#{app_name}'. Expected 'sitesource' or 'grfs'." unless %w[sitesource grfs].include?(app_name)

    app_name
  end
end
