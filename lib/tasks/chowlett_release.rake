require_relative './support/error_chains'

namespace :chowlett_release do
  desc 'Prints a "Hello" message to the console. Verifies that the gem is functional.'
  task ping: :environment do
    require_relative './support/ping'

    Ping.ping
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  desc 'Trigger the workflow'
  task dispatch: :environment do
    Workflow::Trigger.new.run
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end
end
