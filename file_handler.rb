# frozen_string_literal: true

require_relative 'lib/discourse_request'

class FileHandler
  def initialize(markdown)
    @markdown = markdown
    @image_tag_regex = /!\[\[(.*?)\]\]/
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @vault_path = config['vault_path']
  end

  def convert
    @markdown.gsub(@image_tag_regex) do |tag_match|
      image_name = tag_match.match(@image_tag_regex)[1]
      image_path = "#{@vault_path}#{image_name}"
      response = upload_image(image_path)
      short_url = response['short_url']
      original_filename = response['original_filename']
      new_tag = "![#{original_filename}](#{short_url})"
      new_tag
    rescue StandardError => e
      CliErrorHandler.handle_error("Error processing upload #{tag_match}: #{e.message}",
                                   'ProcessingError')
      tag_match
    end
  end

  private

  def upload_image(image_path)
    puts "Uploading file '#{image_path}'"
    client = DiscourseRequest.new
    response = client.upload_file(image_path)
    sleep 1
    response
  end
end
