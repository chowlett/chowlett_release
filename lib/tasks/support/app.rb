# A module provide Application attributes like app_name
module App
  def self.app_name
    app_name = Rails.application.class.module_parent&.name&.downcase

    raise 'Unable to determine the name of the enclosing app.' if app_name.nil? || app_name.empty?
    unless %w[sitesource grfs].include?(app_name)
      raise "Unexpected app name '#{app_name}'. Expected 'sitesource' or 'grfs'."
    end

    app_name
  end
end
