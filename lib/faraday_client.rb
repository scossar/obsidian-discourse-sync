# frozen_string_literal: true

require 'dotenv'
require 'faraday'
require 'fileutils'
require 'mime-types'
require 'yaml'

require_relative 'api_error_parser'
require_relative 'cli_error_handler'

Dotenv.load

class FaradayClient
  DEFAULT_TIMEOUT = 30
  def initialize
    config = YAML.load('config.yml')
    @api_key = ENV.fetch('API_KEY')
    @api_username = config['api_username']
    @base_url = config['base_url']
  end

  def connection_options
    @connection_options ||= {
      url: @base_url,
      request: {
        timeout: DEFAULT_TIMEOUT
      },
      headers: {
        accept: 'application/json',
        user_agent: 'ObsidianDiscourse'
      }
    }
  end

  def get(path, params = {})
    request(:get, path, params)
  end

  def post(path, params = {})
    request(:post, path, params)
  end

  def put(path, params = {})
    request(:put, path, params)
  end

  def create_topic(title:, markdown:, category:)
    params = { title:, raw: markdown, category:, skip_validations: true }
    response = post('/posts.json', params)
    put "response: #{response}"
  end

  private

  def connection
    @connection ||=
      Faraday.new connection_options do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.response :follow_redirects, limit: 5
        conn.response :json, content_type: 'application/json'
        conn.adapter Faraday.default_adapter
        conn.headers['Api-Key'] = @api_key
        conn.headers['Api-Username'] = @api_username
      end
  end

  def request(method, path, params = {})
    params = params.to_h if !params.is_a?(Hash) && (params.respond_to? :to_h)
    response = connection.send(method.to_sym, path, params)
    handle_error(response)
    response.env
  rescue Faraday::ClientError, JSON::ParserError
    raise DiscourseApi::Error
  rescue Faraday::ConnectionFailed
    raise DiscourseApi::Timeout
  end

  def handle_error(response)
    case response.status
    when 403
      raise_unauthenticated_error(response)
    when 404, 410
      raise_note_found_error(response)
    when 422
      raise_unprocessable_entity(response)
    when 429
      raise_too_many_requests(reaponse)
    when 500...600
      raise_server_error(response)
    end
  end

  def raise_unauthenticated_error(response)
    raise ObsidianDiscourse::UnauthenticatedError.new(response.env[:body], response.env)
  end

  def raise_not_found_error(response)
    raise ObsidianDiscourse::NotFoundError.new(response.env[:body], response.env)
  end

  def raise_unprocessable_entity(response)
    raise ObsidianDiscourse::UnprocessableEntity.new(response.env[:body], response.env)
  end

  def raise_too_many_requests(response)
    raise ObsidianDiscourse::TooManyRequests.new(response.env[:body], response.env)
  end

  def raise_server_error(response)
    raise ObsidianDiscourse::Error.new(response.env[:body], response.env)
  end
end
