# frozen_string_literal: true

require 'discourse_api'
require 'dotenv'
require 'front_matter_parser'
require 'yaml'

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

    response = if post_id
                 update_topic_from_note(markdown:,
                                        post_id:)
               else
                 create_topic_for_note(
                   title:, markdown:
                 )
               end
    update_note_data(title, response)
  end

  def parse(content)
    parsed = FrontMatterParser::Parser.new(:md).call(content)
    front_matter = parsed.front_matter
    markdown = parsed.content
    # title = front_matter['title']
    # post_id = front_matter['post_id']
    [markdown, front_matter]
  end

  def create_topic_for_note(title:, markdown:)
    @client.create_topic(category: 8, skip_validations: true, title:,
                         raw: markdown)
  rescue DiscourseApi::UnauthenticatedError, DiscourseApi::Error => e
    error_details = error_details(e)
    if error_details
      error_message = error_message(error_details) || 'Api Error'
      error_type = error_type(error_details)

    else
      error_message = 'Api Error'
      error_type = 'Unknown Error Type'
    end

    handle_error(error_message, error_type)
  end

  def update_topic_from_note(markdown:, post_id:)
    response = @client.edit_post(post_id, markdown)
    case response.status
    when 200, 201, 204
      response.body
    else
      puts "Error: Received status code #{response.status}"
      raise "Failed to update post: #{response.body}"
    end
  rescue DiscourseApi::NotFoundError, DiscourseApi::Error => e
    error_details = error_details(e)
    if error_details
      error_message = error_message(error_details) || 'Api Error'
      error_type = error_type(error_details)
    else
      error_message = 'Api Error'
      error_type = 'Unknown Error Type'
    end
    handle_error(error_message, error_type)
  end

  def update_note_data(title, response)
    discourse_post_id = response['id']
    topic_id = response['topic_id']
    topic_slug = response['topic_slug']

    discourse_url =
      "#{@base_url}/t/#{topic_slug}/#{topic_id}"
    unadjusted_links = 0
    puts "url: #{discourse_url}, discourse_post_id: #{discourse_post_id}"
    puts "discourse_post_id: #{discourse_post_id}"
    Database.create_or_update_note(title:, discourse_url:, discourse_post_id:,
                                   unadjusted_links:)
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

  def error_details(api_error)
    if api_error.respond_to?(:response) && api_error.response.respond_to?(:response_body)
      error_details = api_error.response.response_body
    end
    error_details || nil
  end

  def error_message(error_details)
    if error_details.is_a?(Hash) && error_details['errors'].is_a?(Array)
      error_message = error_details['errors'].join(', ')
    end
    error_message || nil
  end

  def error_type(error_details)
    if error_details.is_a?(Hash) && error_details['error_type']
      error_type = error_details['error_type']
    end
    error_type || nil
  end
end
