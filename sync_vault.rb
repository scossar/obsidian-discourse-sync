# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'yaml'
require_relative 'publish_to_discourse'

class SyncVault
  def initialize(vault_path = nil)
    config = YAML.load_file('config.yml')
    @publisher = PublishToDiscourse.new
    @vault_path = vault_path || config['vault_path']
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
