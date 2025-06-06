# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in strongstart_release.gemspec
gemspec

gem "rake", "~> 13.0"

gem "minitest", "~> 5.16"

gem 'aws-sdk-ecr'
gem 'aws-sdk-ecs'
gem 'aws-sdk-sts'

gem "ostruct"

group :development, :test do
  gem 'rubocop'
end

group :test do
  gem "rails", "~> 8.0" # or your required version
end
