# frozen_string_literal: true

require 'dotenv'
require 'yaml'

Dotenv.load

module DiscourseClient
  def self.client
    @client ||= begin
      config = YAML.load_file('config.yml')
      client = DiscourseApi::Client.new(config['base_url'])
      client.api_key = ENV.fetch('API_KEY')
      client.api_username = config['api_username']
      client
    end
  end
end
