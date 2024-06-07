# frozen_string_literal: true

require 'discourse_api'
require 'mime-types'

require_relative 'lib/discourse_client'

class LocalToDiscourseImageConverter
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
      puts "image_name: #{image_path}"
      response = upload_image_to_discourse(image_path)
      p response
      sleep 1
    end
    @markdown
  end

  private

  def upload_image_to_discourse(image_path)
    file_name = File.basename(image_path)
    mime_type = MIME::Types.type_for(file_name).first.to_s
    file = Faraday::UploadIO.new(image_path, mime_type)
    DiscourseClient.client.upload_file(file:, synchronous: true,
                                       type: 'composer')
  end
end
