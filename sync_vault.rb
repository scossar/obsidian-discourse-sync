# frozen_string_literal: true

require 'fileutils'
require 'yaml'

class SyncVault
  def initialize
    load_config
  end

  def load_config
    config = YAML.load_file('config.yml')
    @vault_path = config['vault_path']
  end

  def sync
    Dir.glob(File.join(@vault_path, '**', '*.md')).each do |file|
      puts "File: #{file}"
      puts "Directory: #{File.dirname(file)}"
      puts "Last Modified: #{File.mtime(file)}"
      puts '---------'
    end
  end
end

obj = SyncVault.new
obj.sync
