# frozen_string_literal: true

require_relative 'faraday_client'

class DiscourseRequest
  def initialize
    @faraday_client = FaradayClient.new
  end

  def create_topic(title:, markdown:, category:)
    params = { title:, raw: markdown, category:, skip_validations: true }
    @faraday_client.post('/posts.json', params)
  end

  def update_post(markdown:, post_id:)
    params = { post: { raw: markdown } }
    @faraday_client.put("/posts/#{post_id}.json", params)
  end

  def upload_file(file_path)
    file_name = File.basename(file_path)
    mime_type = MIME::Types.type_for(file_name).first.to_s
    file = Faraday::UploadIO.new(file_path, mime_type)
    params = { file:, synchronous: true, type: 'composer' }
    @faraday_client.post('/uploads.json', params)
  end

  def site_info
    @faraday_client.get('/site.json')
  end
end
