require "rails/railtie"

module StrongstartRelease
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../../lib/tasks/strongstart_release.rake", __FILE__)
    end
  end
end
