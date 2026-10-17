class Whatsapp::Providers::CloudCampaignService < Whatsapp::Providers::WhatsappCloudService
  def send_campaign_template(phone_number, template_info, recipient_id:)
    response = HTTParty.post("#{phone_id_path}/messages", headers: api_headers,
                                                          body: payload(phone_number, template_info, recipient_id).to_json, **http_timeouts)
    result(response)
  end

  private

  def payload(phone_number, template_info, recipient_id)
    { messaging_product: 'whatsapp', recipient_type: 'individual', **recipient_params(phone_number),
      type: 'template', template: template_body_parameters(template_info), biz_opaque_callback_data: "campaign_recipient:#{recipient_id}" }
  end

  def result(response)
    body = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
    id = body.dig('messages', 0, 'id')
    return { state: 'accepted', provider_message_id: id } if response.success? && id.present?

    rejection(response, body.dig('error', 'code'))
  end

  def rejection(response, code)
    if response.code == 429 || [130_429, 131_056].include?(code)
      return { state: 'retryable', error_code: code ? "meta_#{code}" : 'http_429', retry_after: retry_after(response) }
    end

    { state: response.code >= 500 || response.success? ? 'unknown' : 'failed', error_code: code ? "meta_#{code}" : "http_#{response.code}" }
  end

  def retry_after(response)
    value = response.headers['retry-after']
    return 0 if value.blank?

    Integer(value, exception: false) || [Time.httpdate(value) - Time.current, 0].max.ceil
  rescue ArgumentError
    0
  end
end
