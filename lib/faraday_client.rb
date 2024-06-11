# frozen_string_literal: true

require 'dotenv'
require 'faraday'
require 'fileutils'
require 'mime-types'
require 'yaml'

require_relative 'cli_error_handler'

Dotenv.load

class FaradayClient
  DEFAULT_TIMEOUT = 30

  def initialize
    config = YAML.load_file('config.yml')
    @api_key = ENV.fetch('API_KEY')
    @api_username = config['api_username']
    @base_url = config['base_url']
  end

  def create_topic(title:, markdown:, category:)
    params = { title:, raw: markdown, category:, skip_validations: true }
    post('/posts.json', params)
  end

  def update_post(markdown:, post_id:)
    params = { post: { raw: markdown } }
    put("/posts/#{post_id}.json", params)
  end

  def upload_file(file_path)
    file_name = File.basename(file_path)
    mime_type = MIME::Types.type_for(file_name).first.to_s
    file = Faraday::UploadIO.new(file_path, mime_type)
    params = { file:, synchronous: true, type: 'composer' }
    post('/uploads.json', params)
  end

  private

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
    response = request(:post, path, params)
    response.body
  end

  def put(path, params = {})
    response = request(:put, path, params)
    response.body
  end

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
  rescue Faraday::ConnectionFailed => e
    rescue_error(e, 'connection_failed')
  rescue Faraday::TimeoutError => e
    rescue_error(e, 'timeout')
  rescue Faraday::SSLError => e
    rescue_error(e, 'ssl_error')
  rescue Faraday::Error => e
    rescue_error(e, 'unknown_error')
  end

  def handle_error(response)
    case response.status
    when 403
      raise_unauthenticated_error
    when 404, 410
      raise_not_found_error
    when 422
      raise_unprocessable_entity
    when 429
      raise_too_many_requests
    when 500...600
      raise_server_error
    end
  end

  def rescue_error(error, error_type)
    CliErrorHandler.handle_error(error.message, error_type)
  end

  def raise_unauthenticated_error
    CliErrorHandler.handle_error('Unauthenticated access', 'invalid_access')
  end

  def raise_not_found_error
    CliErrorHandler.handle_error('Resource not found', 'not_found')
  end

  def raise_unprocessable_entity
    CliErrorHandler.handle_error('Unprocessable entity', 'unprocessable_entity')
  end

  def raise_too_many_requests
    CliErrorHandler.handle_error('Too many requests', 'too_many_requests')
  end

  def raise_server_error
    CliErrorHandler.handle_error('Server error', 'server_error')
  end
end
