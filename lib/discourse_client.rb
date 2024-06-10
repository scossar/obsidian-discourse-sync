# frozen_string_literal: true

require 'dotenv'
require 'faraday'
require 'json'
require 'yaml'

require_relative 'api_error_parser'
require_relative 'cli_error_handler'

Dotenv.load

module DiscourseClient
  class << self
    def faraday_client
      @faraday_client ||= begin
        config = YAML.load_file('config.yml')
        api_key = ENV.fetch('API_KEY')
        api_username = config['api_username']
        base_url = config['base_url']
        headers = { 'Content-Type' => 'application/json', 'Api-Key' => api_key,
                    'Api-Username' => api_username }
        Faraday.new(url: base_url, headers:)
      end
    end

    def create_topic(title:, markdown:, category:)
      body = { title:, raw: markdown, category:, skip_validations: true }.to_json
      response = faraday_client.post('/posts.json', body)
      case response.status
      when 200, 201, 204
        JSON.parse(response.body)
      else
        CliErrorHandler.handle_error("Unable to create topic for #{title}", 'Unknown error')
      end
    rescue Faraday::Error, Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError => e
      error_message, error_type = ApiErrorParser.message_and_type(e)
      CliErrorHandler.handle_error(error_message, error_type)
    end

    def update_post(markdown:, post_id:)
      body = { post: { raw: markdown } }.to_json
      response = faraday_client.put("/posts/#{post_id}.json", body)
      case response.status
      when 200, 201, 204
        JSON.parse(response.body)
      else
        CliErrorHandler.handle_error("Unable to create post for #{title}", 'Unknown error')
      end
    rescue Faraday::Error, Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError => e
      error_message, error_type = ApiErrorParser.message_and_type(e)
      CliErrorHandler.handle_error(error_message, error_type)
    end

    def client
      @client ||= begin
        config = YAML.load_file('config.yml')
        client = DiscourseApi::Client.new(config['base_url'])
        client.api_key = ENV.fetch('API_KEY')
        client.api_username = config['api_username']
        client
      end
    end
  end
end
