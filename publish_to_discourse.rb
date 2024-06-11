# frozen_string_literal: true

require 'discourse_api'
require 'fileutils'
require 'front_matter_parser'
require 'json'
require 'yaml'

require_relative 'lib/api_error_parser'
require_relative 'lib/cli_error_handler'
require_relative 'lib/database'
require_relative 'lib/utils'
require_relative 'internal_link_handler'
require_relative 'local_to_discourse_image_converter'

class PublishToDiscourse
  def initialize
    @client = DiscourseClient.client
    @faraday_client = DiscourseClient.faraday_client
    config = YAML.load_file('config.yml')
    @base_url = config['base_url']
  end

  def publish(file_path)
    begin
      title = Utils.title_from_file_path(file_path)
    rescue ArgumentError => e
      CliErrorHandler.handle_error(e.message, 'invalid_file')
      return
    end
    content = File.read(file_path)
    post_id = Database.get_discourse_post_id(title)
    markdown, _front_matter = parse(content)
    image_converter = LocalToDiscourseImageConverter.new(markdown)
    markdown = image_converter.convert
    link_handler = InternalLinkHandler.new(markdown)
    markdown = link_handler.handle
    if post_id
      update_topic_from_note(title:, markdown:, post_id:)
    else
      create_topic(title:, markdown:, category: 8)
    end
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    [markdown, front_matter]
  end

  def create_topic(title:, markdown:, category:)
    puts "Creating full topic for '#{title}'"
    response = DiscourseClient.create_topic(title:, markdown:, category:)
    add_note_to_db(title, response)
    sleep 1
  end

  def update_topic_from_note(title:, markdown:, post_id:)
    puts "Updating post for '#{title}'"
    DiscourseClient.update_post(markdown:, post_id:)
    sleep 1
  end

  def add_note_to_db(title, response)
    discourse_post_id = response['id']
    topic_id = response['topic_id']
    topic_slug = response['topic_slug']
    discourse_url = "#{@base_url}/t/#{topic_slug}/#{topic_id}"
    Database.create_note(title:, discourse_url:, discourse_post_id:)
  end
end
