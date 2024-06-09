# frozen_string_literal: true

require_relative 'lib/database'

class InternalLinkHandler
  def initialize(markdown)
    @markdown = markdown
    @client = DiscourseClient.client
    @internal_link_regex = /\[\[(.*?)\]\]/
  end

  def handle
    @markdown.gsub(@internal_link_regex) do |link_match|
      title = link_match.match(@internal_link_regex)[1]
      discourse_url = Database.get_discourse_url_from_title(title)
      discourse_url ||= create_placeholder_topic(title:)
      new_link = "[#{title}](#{discourse_url})"
      new_link
    end
  end

  def create_placeholder_topic(title:)
    raw = "This is a placeholder topic for #{title}"
    response = @client.post('posts', title:, raw:, category: 8, skip_validations: true)
    add_note_to_db(title, response)
  rescue DiscourseApi::UnauthenticatedError, DiscourseApi::Error => e
    error_message, error_type = ApiErrorParser.message_and_type(e)
    CliErrorHandler.handle_error(error_message, error_type)
  end

  def add_note_to_db(title, response)
    discourse_post_id = response['id']
    topic_id = response['topic_id']
    topic_slug = response['topic_slug']
    discourse_url =
      "#{@base_url}/t/#{topic_slug}/#{topic_id}"
    Database.create_note(title:, discourse_url:, discourse_post_id:)
    discourse_url
  end
end
