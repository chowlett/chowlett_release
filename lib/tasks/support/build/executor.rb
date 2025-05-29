require_relative '../app'

module Build
  class Executor
    attr_accessor :app_name, :run_tests_please

    def execute
      puts "Building #{app_name}"
      tests
    rescue StandardError => e
      puts "Error during build: #{e.message}"
      puts 'Build aborted.'
    end

    def initialize(run_tests_please: true)
      self.app_name =App.app_name
      self.run_tests_please = run_tests_please
    end

    private

    def tests
      unless run_tests_please
        puts "Skipping tests as requested."
        return
      end

      system("bundle exec rake test")
      exit_code = $?.exitstatus
      puts "exit code from tests: #{exit_code}"

      raise "Test run failed with exit code #{exit_code}" unless exit_code.zero?
    end
  end
end