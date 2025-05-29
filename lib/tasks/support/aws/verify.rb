require 'aws-sdk-sts'

module Aws
  module Verify
    def self.verify
      client = Aws::STS::Client.new
      resp = client.get_caller_identity

      begin
        puts "Region: #{client&.config&.region}"
      rescue StandardError => e
        puts "Error retrieving AWS region: #{e.message}"
      end

      puts "Account: #{resp.account}"
      puts "UserId: #{resp.user_id}"
      puts "ARN: #{resp.arn}"
    rescue StandardError => e
      puts "Error verifying AWS credentials: #{e.message}"
    end
  end
end