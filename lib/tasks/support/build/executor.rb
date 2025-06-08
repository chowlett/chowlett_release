require_relative '../app'
require_relative './version_tag'
require_relative './error'
require Rails.root.join('docker-build', 'version_tag').to_s
require 'pathname'
require 'open3'
require 'English'

module Build
  # Run the application build.
  class Executor
    VERSION_FILE_PATH = Rails.root.join('docker-build', 'version.json').to_s
    ECR_REGISTRY = '938158173016.dkr.ecr.ca-central-1.amazonaws.com'.freeze

    attr_accessor :run_tests_please, :dry_run_please, :app_brand_name, :app_name, :branch, :version

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      start_time = Time.now
      puts "Building #{app_name}"
      puts 'Dry run' if dry_run_please

      if run_tests_please
        tests
      else
        puts 'Skipping tests per your request.'
      end

      ecr_login
      change_to_context_dir
      prepare_branch
      prepare_version
      puts "Building #{app_brand_name} image #{branch_version}"

      docker_build

      save_version unless dry_run_please

      elapsed_time = Time.now - start_time
      puts format(
        'Completed building %<app_brand_name>s image %<branch_version>s, elapsed %<elapsed_time>.1f secs.',
        app_brand_name:,
        branch_version:,
        elapsed_time:
      )
      puts 'Image built locally but not pushed to ECR because you specified --dry-run.' if dry_run_please
    rescue StandardError
      raise Build::Error # Build::Error provides an error message. Error details are in the cause.
    end

    def initialize(run_tests_please: true, dry_run_please: false)
      self.app_name = App.app_name
      self.run_tests_please = run_tests_please
      self.dry_run_please = dry_run_please
      self.app_brand_name = app_name == 'sitesource' ? 'SiTE SOURCE' : 'GRFS'
    end

    private

    def tests
      puts "Running tests for #{app_name}..."
      system('bundle exec rake test')
      exit_code = $CHILD_STATUS&.exitstatus
      raise "Test run failed with exit code #{exit_code}" unless exit_code&.zero?

      puts 'Tests passed'
    end

    def change_to_context_dir
      Dir.chdir Rails.root
    end

    def prepare_branch
      self.branch = `git branch --show-current`.strip
      return unless branch.nil? || branch.empty?

      raise 'Fatal. Unable to determine git branch.'
    end

    def prepare_version
      self.version = VersionTag.new(VERSION_FILE_PATH)
      version.inc
    end

    def docker_build_command
      cmd_parts = [
        'DOCKER_BUILDKIT=1',
        'docker buildx build',
        "--secret id=bundle_config,src=#{ENV['HOME']}/.bundle/config",
        '-t ',
        "#{ECR_REGISTRY}/#{app_name}:#{branch_version}",
        '--platform linux/arm64'
      ]
      cmd_parts << '--push' unless dry_run_please
      cmd_parts << '.'

      cmd_parts.join(' ')
    end

    def docker_build
      cmd = docker_build_command
      puts "Docker build command: #{cmd}" if dry_run_please
      output = `#{cmd}`
      rc = $CHILD_STATUS&.exitstatus

      process_docker_build_output output

      return if rc&.zero?

      puts "Exit code from docker build: #{rc}. Build log: #{build_log_path}"
      raise "Docker build command failed with exit code #{rc}"
    end

    def process_docker_build_output(output)
      puts output
      build_log_path = Rails.root.join('log', "build-#{branch_version}.log")
      File.write(build_log_path, output)
    rescue StandardError => e
      puts "Error (non-fatal) writing build log: #{e.inspect}"
    end

    def ecr_login # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      login_cmd = 'aws ecr get-login-password | ' \
        "docker login --username AWS --password-stdin #{ECR_REGISTRY}"

      Open3.popen3(login_cmd) do |_stdin, stdout, stderr, thread|
        process_status = thread.value
        rc = process_status.exitstatus
        stdout_lines = stdout.readlines.join('')
        stderr_lines = stderr.readlines.join('')
        if rc.zero?
          puts stdout_lines
        else
          puts "login stdout: #{stdout_lines}" unless stdout_lines.strip == ''
          puts "login stderr: #{stderr_lines}" unless stderr_lines.strip == ''
          puts('Fatal error')
          exit(8)
        end
      end
    rescue StandardError => e
      puts("Fatal docker login error: #{e.class} #{e}")
      exit(8)
    end

    def save_version
      version.save VERSION_FILE_PATH
    end

    def branch_version
      "#{branch}-#{version}"
    end
  end
end
