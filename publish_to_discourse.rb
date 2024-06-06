# frozen_string_literal: true

require 'dotenv'
require 'front_matter_parser'
require 'httparty'
require 'yaml'

Dotenv.load

class PublishToDiscourse
  def initialize
    @filename = filename
    @api_key = ENV.fetch('API_KEY')
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @api_username = config['api_username']
    @base_url = config['base_url']
    @vault_path = config['vault_path']
  end

  def publish(filename)
    content = File.read("#{@vault_path}#{filename}")
    _parsed, markdown, title, post_id = parse(content)

    return unless title

    response = publish_note(title:, post_id:, markdown:)
    return unless response.message == 'OK'

    JSON.parse(response.body)
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    title = front_matter['title']
    post_id = front_matter['post_id']
    [parsed, markdown, title, post_id]
  end

  def publish_note(title:, post_id:, markdown:)
    headers = { 'Api-Key' => @api_key, 'Api-Username' => @api_username,
                'Content-Type' => 'application/json' }
    url = post_id ? "#{@base_url}/#{post_id}.json" : "#{@base_url}/posts.json"
    puts "url: #{url}"
    body = JSON.generate({ title:, raw: markdown, category: 8,
                           skip_validations: true })
    method = post_id ? :put : :post
    HTTParty.send(method, url, headers:, body:)
  end
end

# obj = PublishToDiscourse.new(ARGV[0])
# obj.publish
