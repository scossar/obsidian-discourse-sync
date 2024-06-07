# frozen_string_literal: true

require 'dotenv'
require 'front_matter_parser'
require 'httparty'
require 'yaml'

require_relative 'local_to_discourse_image_converter'

Dotenv.load

class PublishToDiscourse
  def initialize
    @api_key = ENV.fetch('API_KEY')
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @api_username = config['api_username']
    @base_url = config['base_url']
    @vault_path = config['vault_path']
  end

  def publish(file)
    content = File.read(file)
    _parsed, markdown, title, post_id, front_matter = parse(content)

    return unless title

    image_converter = LocalToDiscourseImageConverter.new(markdown)
    markdown = image_converter.convert

    response = publish_note(title:, post_id:, markdown:)
    return unless response.message == 'OK'

    topic_json = JSON.parse(response.body)
    update_front_matter(topic_json:, front_matter:, markdown:, file:)
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    title = front_matter['title']
    post_id = front_matter['post_id']
    [parsed, markdown, title, post_id, front_matter]
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

  def update_front_matter(topic_json:, front_matter:, markdown:, file:)
    front_matter['post_id'] = topic_json['id']
    front_matter['discourse_url'] =
      "#{@base_url}/t/#{topic_json['topic_slug']}/#{topic_json['topic_id']}"
    updated_content = "#{front_matter.to_yaml}---\n#{markdown}"
    File.write(file, updated_content)
  end
end

obj = PublishToDiscourse.new
obj.publish ARGV[0]
