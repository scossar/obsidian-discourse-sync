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
    @directory_category_map = {}
  end

  def sync
    unique_directories.each do |directory|
      category = select_category_for_directory(directory)
      sync_files_in_directory(directory, category)
    end
  end

  def sync_bak
    Dir.glob(File.join(@vault_path, '**', '*.md')).each do |file_path|
      puts "Syncing file: #{file_path}"
      puts "Directory: #{File.dirname(file_path)}"
      puts "Last Modified: #{File.mtime(file_path)}"
      puts '---------'
      # @publisher.publish file_path
      sleep 1
    end
  end

  private

  def unique_directories
    directories = Dir.glob(File.join(@vault_path, '**', '*.md')).map do |file_path|
      File.dirname(file_path)
    end
    directories.uniq
  end

  def select_category_for_directory(directory)
    unless @directory_category_map[directory]
      puts "Select a Discourse category for the directory: #{directory}"
      @categories.each_key do |key|
        puts @categories[key][:name]
        choice = key
        @directory_category_map[directory] = choice
      end
    end
    @directory_category_map[directory]
  end

  def sync_files_in_directory(directory, _category)
    Dir.glob(File.join(directory, '*.md')).each do |file_path|
      puts "Syncing file: #{file_path}"
      puts "Directory: #{directory}"
      puts "Last Modified: #{File.mtime(file_path)}"
      puts '---------'
      # @publisher.publish(file_path, category)
      sleep 1
    end
  end
end
