# frozen_string_literal: true

require 'optparse'

require_relative 'publish_to_discourse'
require_relative 'sync_vault'

options = {}
command = nil

OptionParser.new do |opts|
  opts.banner = 'Usage: obsidian_discourse.rb [command] [options]'

  opts.on('-p', '--vault_path PATH', 'Path to vault') do |p|
    options[:vault_path] = p
  end

  opts.on('-f', '--file_path PATH', 'Path to file') do |f|
    options[:file_path] = f
  end

  opts.on('-c', '--command COMMAND',
          'Command to execute (sync_vault, publish_to_discourse)') do |c|
    command = c
  end

  opts.on('-v', '--version', 'Show version') do
    puts 'obsidian_discourse version 0.0.1'
    exit
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end.parse!

case command
when 'sync_vault'
  vault_path = options[:vault_path]
  puts "vault_path: #{vault_path}"
  sync_vault = SyncVault.new(vault_path)
  sync_vault.sync
when 'publish_to_discourse'
  file = options[:file_path]
  publisher = PublishToDiscourse.new
  publisher.publish(file)
else
  puts 'Invalid command. Use -h for help.'
end
