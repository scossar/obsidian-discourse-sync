# frozen_string_literal: true

require 'discourse_api'
require 'dotenv'
require 'front_matter_parser'
require 'yaml'

require_relative 'lib/api_error_parser'
require_relative 'lib/database'
require_relative 'local_to_discourse_image_converter'

Dotenv.load

class PublishToDiscourse
  def initialize
    @api_key = ENV.fetch('API_KEY')
    @client = DiscourseClient.client
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
    markdown, _front_matter = parse(content)
    image_converter = LocalToDiscourseImageConverter.new(markdown)
    markdown = image_converter.convert
    if post_id
      update_topic_from_note(markdown:,
                             post_id:)
    else
      create_topic_for_note(
        title:, markdown:
      )
    end
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    [markdown, front_matter]
  end

  def create_topic_for_note(title:, markdown:)
    response = @client.create_topic(category: 8, skip_validations: true, title:,
                                    raw: markdown)
    add_note_to_db(title, response)
  rescue DiscourseApi::UnauthenticatedError, DiscourseApi::Error => e
    error_message, error_type = ApiErrorParser.message_and_type(e)
    handle_error(error_message, error_type)
  end

  def update_topic_from_note(markdown:, post_id:)
    response = @client.edit_post(post_id, markdown)
    case response.status
    when 200, 201, 204
      response.body
    else
      raise "Failed to update post: #{response.body}"
    end
  rescue DiscourseApi::NotFoundError, DiscourseApi::Error => e
    error_message, error_type = ApiErrorParser.message_and_type(e)
    handle_error(error_message, error_type)
  end

  def add_note_to_db(title, response)
    discourse_post_id = response['id']
    topic_id = response['topic_id']
    topic_slug = response['topic_slug']
    discourse_url =
      "#{@base_url}/t/#{topic_slug}/#{topic_id}"
    Database.create_note(title:, discourse_url:, discourse_post_id:)
  end

  def title_from_file(file)
    file_name = file.split('/')[-1]
    file_name.split('.')[0]
  end

  def handle_error(message, error_type)
    puts message
    if error_type == 'invalid_access'
      puts 'Make sure you have added your API key to the .env file'
    end
    puts 'Would you like to continue with the syncing process? (yes/no)'
    answer = gets.chomp.downcase
    if answer == 'yes'
      puts 'Continuing with the syncing process...'
    else
      puts 'Quitting the process...'
      exit
    end
  end
end
