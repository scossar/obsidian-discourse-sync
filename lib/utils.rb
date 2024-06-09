# frozen_string_literal: true

require 'fileutils'

module Utils
  def self.title_from_file_path(file_path)
    File.basename(file_path, '.md')
  end
end
