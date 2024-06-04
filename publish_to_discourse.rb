# frozen_string_literal: true

# require 'front_matter_parser'
require 'json'
require 'net-http'
require 'uri'

def publish_to_discourse(_file_path)
  # content = File.read(file_path)
  # parsed = FrontMatterParser::Parser.parse_file(file_path)
  # front_matter = parsed.front_matter
  File.write('obsidian.txt', 'this is a test', mode: 'a')
end
