require 'rails/railtie'

module ChowlettRelease
  # Railtie to load the chowlett_release Rake tasks into a Rails application.
  class Railtie < Rails::Railtie
    rake_tasks do
      # __dir can return nil, and inspection does not assume it is idempotent/ Accordingly, capture it in a variable.
      relative_to = __dir__
      load File.expand_path('../../lib/tasks/chowlett_release.rake', relative_to) unless relative_to.nil?
    end
  end
end
