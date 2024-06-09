# frozen_string_literal: true

module ApiErrorParser
  def self.message_and_type(api_error)
    details = error_details(api_error)
    message = error_message(details)
    type = error_type(details)
    [message, type]
  end

  def self.error_details(api_error)
    if api_error.respond_to?(:response) && api_error.response.respond_to?(:response_body)
      error_details = api_error.response.response_body
    end
    error_details || nil
  end

  def self.error_message(error_details)
    if error_details.is_a?(Hash) && error_details['errors'].is_a?(Array)
      error_message = error_details['errors'].join(', ')
    end
    error_message || nil
  end

  def self.error_type(error_details)
    if error_details.is_a?(Hash) && error_details['error_type']
      error_type = error_details['error_type']
    end
    error_type || nil
  end
end
