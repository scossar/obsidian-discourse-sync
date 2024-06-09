# frozen_string_literal: true

module CliErrorHandler
  def self.handle_error(message, error_type)
    puts message
    if error_type == 'invalid_access'
      puts 'Make sure you have added your API key to the .env file'
    end
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
