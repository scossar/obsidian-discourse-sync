# frozen_string_literal: true

require 'fileutils'

module Utils
  def self.title_from_file_path(file_path)
    raise ArgumentError, 'Invalid file extension' unless file_path.end_with?('.md')

    File.basename(file_path, '.md')
  end
end
