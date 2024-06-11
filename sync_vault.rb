# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'discourse_category_fetcher'
require_relative 'publish_to_discourse'

class SyncVault
  def initialize(vault_path = nil)
    config = YAML.load_file('config.yml')
    @publisher = PublishToDiscourse.new
    @vault_path = vault_path || config['vault_path']
    @categories = DiscourseCategoryFetcher.instance.categories
    puts "categories: #{@categories}"
  end

  def sync
    Dir.glob(File.join(@vault_path, '**', '*.md')).each do |file_path|
      puts "Syncing file: #{file_path}"
      puts "Directory: #{File.dirname(file_path)}"
      puts "Last Modified: #{File.mtime(file_path)}"
      puts '---------'
      # @publisher.publish file_path
      sleep 1
    end
  end
end
