# frozen_string_literal: true

require 'dotenv'
require 'front_matter_parser'
require 'httparty'
require 'yaml'

require_relative 'lib/database'
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
    title = title_from_file(file)
    post_id = Database.get_discourse_post_id(title)
    puts "post_id: #{post_id}, title: #{title}"
    markdown, _title, _post_id = parse(content)

    return unless title

    markdown_copy = markdown.dup
    image_converter = LocalToDiscourseImageConverter.new(markdown_copy)
    updated_markdown = image_converter.convert

    response = publish_note(title:, post_id:, markdown: updated_markdown)
    puts "response.message: #{response.message}"
    return unless response.message == 'OK'

    topic_json = JSON.parse(response.body)
    update_note_data(title, topic_json)
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    title = front_matter['title']
    post_id = front_matter['post_id']
    [markdown, title, post_id]
  end

  def publish_note(title:, post_id:, markdown:)
    puts "post_id: #{post_id}"
    headers = { 'Api-Key' => @api_key, 'Api-Username' => @api_username,
                'Content-Type' => 'application/json' }
    url = post_id ? "#{@base_url}/posts/#{post_id}.json" : "#{@base_url}/posts.json"
    puts "url: #{url}"
    body = JSON.generate({ title:, raw: markdown, category: 8,
                           skip_validations: true })
    method = post_id ? :put : :post
    HTTParty.send(method, url, headers:, body:)
  end

  def update_note_data(title, topic_json)
    discourse_url =
      "#{@base_url}/t/#{topic_json['topic_slug']}/#{topic_json['topic_id']}"
    discourse_post_id = topic_json['id']
    unadjusted_links = 0
    Database.create_or_update_note(title:, discourse_url:, discourse_post_id:,
                                   unadjusted_links:)
  end

  def title_from_file(file)
    file_name = file.split('/')[-1]
    file_name.split('.')[0]
  end
end
