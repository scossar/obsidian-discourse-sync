# frozen_string_literal: true

class LocalToDiscourseImageConverter
  def initialize(markdown)
    @markdown = markdown
    @image_tag_regex = /!\[\[(.*?)\]\]/
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @api_username = config['api_username']
    @base_url = config['base_url']
    @vault_path = config['vault_path']
  end

  def convert
    @markdown.gsub(@image_tag_regex) do |tag_match|
      image_name = tag_match.match(@image_tag_regex)[1]
      puts "image_name: #{image_name}"
    end
    @markdown
  end
end
