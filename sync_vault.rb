# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'publish_to_discourse'

class SyncVault
  def initialize
    @publisher = PublishToDiscourse.new
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @vault_path = config['vault_path']
  end

  def sync
    Dir.glob(File.join(@vault_path, '**', '*.md')).each do |file|
      puts "Syncing file: #{file}"
      puts "Directory: #{File.dirname(file)}"
      puts "Last Modified: #{File.mtime(file)}"
      puts '---------'
      @publisher.publish file
      sleep 1
    end
  end
end

obj = SyncVault.new
obj.sync
