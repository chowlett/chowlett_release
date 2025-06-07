require 'json'

# Simple version number management
class VersionTag
  attr_accessor :major, :minor, :build

  def initialize(path)
    version_hash = JSON.parse(File.read(path))
    self.major = version_hash['major']
    self.minor = version_hash['minor']
    self.build = version_hash['build']
  end

  def save(path)
    s = JSON.generate(major:, minor:, build:)

    File.write(path, s)
  end

  def inc
    self.build += 1
  end

  def to_s
    "#{major}.#{minor}.#{build}"
  end
end
