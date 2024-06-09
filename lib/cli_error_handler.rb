# frozen_string_literal: true

module CliErrorHandler
  def self.handle_error(message, error_type)
    puts "Error: #{message}"
    case error_type
    when 'invalid_access'
      puts 'Make sure you have added your API key to the .env file'
      exit
    when 'invalid_file'
      puts 'The file provided does not have a .md extension.'
      exit
    else
      prompt_to_continue
    end
  end

  def self.prompt_to_continue
    puts 'Would you like to continue with the syncing process? (yes/no)'
    answer = gets.chomp.downcase
    if answer == 'yes'
      puts 'Continuing with the syncing process...'
    else
      puts 'Quitting the process...'
      exit
    end
  end
end
