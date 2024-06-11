# frozen_string_literal: true

require_relative 'lib/faraday_client'

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
      begin
        response = upload_image(image_path)
        if response['errors']
          puts "Failed to upload image: #{response['errors']}"
          tag_match
        else
          short_url = response['short_url']
          original_filename = response['original_filename']
          new_tag = "![#{original_filename}](#{short_url})"
          new_tag
        end
      rescue StandardError
        tag_match
      ensure
        sleep 1
      end
    end
  end

  private

  def upload_image(image_path)
    puts "Uploading file '#{image_path}'"
    client = FaradayClient.new
    client.upload_file(image_path)
  end
end
