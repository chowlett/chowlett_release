require_relative '../app'
require Rails.root.join('docker-build', 'version_tag').to_s
require 'pathname'
require 'open3'

module Build
  class Executor
    VERSION_FILE_PATH = Rails.root.join('docker-build', 'version.json').to_s
    ECR_REGISTRY = '938158173016.dkr.ecr.ca-central-1.amazonaws.com'

    attr_accessor :run_tests_please
    attr_accessor :appBrandName
    attr_accessor :app_name
    attr_accessor :branch
    attr_accessor :version

    def execute
      start_time = Time.now
      puts "Building #{app_name}"
      tests

      ecr_login
      change_to_context_dir
      prepare_branch
      prepare_version
      puts "Building #{appBrandName} image #{branch_version}"

      docker_build

      save_version

      elapsed_time = Time.now - start_time
      puts "Completed building #{appBrandName} image #{branch_version}, elapsed #{'%.1f' % elapsed_time} secs."

    rescue StandardError => e
      puts "Error during build: #{e.message}"
      puts 'Build aborted.'
    end

    def initialize(run_tests_please: true)
      self.app_name =App.app_name
      self.run_tests_please = run_tests_please
      self.appBrandName = app_name == 'sitesource' ? 'SiTE SOURCE' : 'GRFS'
    end

    private

    def tests
      unless run_tests_please
        puts "Skipping all of the tests because you have opted not to run them."
        return
      end

      puts "Running tests for #{app_name}..."
      system("bundle exec rake test")
      exit_code = $?.exitstatus
      raise "Test run failed with exit code #{exit_code}" unless exit_code.zero?

      puts "Tests passed"
    end

    def change_to_context_dir
      Dir.chdir Rails.root
    end

    def prepare_branch
      self.branch = `git branch --show-current`.strip
      if branch.nil? || branch.length == 0
        puts("Fatal. Unable to determine git branch.")
        exit(8)
      end
    end

    def prepare_version
      self.version = VersionTag.new(VERSION_FILE_PATH)
      version.inc
    end

    def docker_build
      cmds = [
        "docker buildx build -t #{ECR_REGISTRY}/#{app}:#{branch_version} --platform linux/arm64 --push ."
      ]

      cmds.each do |cmd|
        puts cmd
        output = `#{cmd}`
        rc = $?.exitstatus

        puts output
        puts "rc = #{rc}"

        if rc != 0
          puts 'Command failed, terminating'
          exit 8
        end
      end
    end

    def ecr_login
      login_cmd = "aws ecr get-login-password | "\
        "docker login --username AWS --password-stdin #{ECR_REGISTRY}"

      Open3.popen3(login_cmd) do |stdin, stdout, stderr, thread|
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