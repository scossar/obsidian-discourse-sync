# frozen_string_literal: true

require 'singleton'
require_relative 'lib/discourse_request'

class DiscourseCategoryFetcher
  include Singleton

  attr_reader :categories

  def initialize
    @categories = fetch_categories
  end

  private

  def fetch_categories
    client = DiscourseRequest.new
    site_info = client.site_info
    categories = site_info['categories']
    parsed_categories = parse_categories(categories)
    fix_category_names(parsed_categories)
  end

  def parse_categories(categories)
    categories.each_with_object({}) do |cat, result|
      cat_hash = cat.to_h
      result[cat_hash['id']] = {
        id: cat_hash['id'],
        name: cat_hash['name'],
        slug: cat_hash['slug'],
        read_restricted: cat_hash['read_restricted'],
        parent_category_id: cat_hash['parent_category_id']
      }
    end
  end

  def fix_category_names(parsed_categories)
    parsed_categories.each_value do |category|
      if category[:parent_category_id]
        parent_category = parsed_categories[category[:parent_category_id]]
        category[:name] = "#{parent_category[:name]}/#{category[:name]}"
      end
    end
    parsed_categories
  end
end
