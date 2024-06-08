# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'yaml'
require_relative 'publish_to_discourse'
require_relative 'lib/database'

class SyncVault
  def initialize(vault_path = nil)
    Database.initialize_database
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

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: sync_vault.rb [options]'

  opts.on('v', '--vault_path PATH', 'Path to vault') do |v|
    options[:vault_path] = v
  end
end.parse!

vault_path = options[:vault_path]
sync_vault = SyncVault.new(vault_path)
sync_vault.sync
