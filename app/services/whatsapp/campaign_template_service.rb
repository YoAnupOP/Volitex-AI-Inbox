class Whatsapp::CampaignTemplateService
  class InvalidTemplate < StandardError; end

  pattr_initialize [:campaign!]

  def validate!
    params = campaign.template_params
    template = Array(campaign.inbox.channel.message_templates).find do |item|
      item['name'] == params&.dig('name') && item['language'].to_s.casecmp?(params&.dig('language').to_s) &&
        item['status'].to_s.casecmp?('approved') && item['category'].to_s.casecmp?('marketing')
    end
    raise InvalidTemplate, 'Approved marketing template required' unless template
  end

  def for_contact(contact)
    validate!
    params = Whatsapp::LiquidTemplateProcessorService.new(campaign: campaign, contact: contact).process_template_params(campaign.template_params)
    raise InvalidTemplate, 'Invalid personalized template parameters' unless params

    name, namespace, language, parameters = Whatsapp::TemplateProcessorService.new(channel: campaign.inbox.channel, template_params: params).call
    { name: name, namespace: namespace, lang_code: language, parameters: parameters }
  end
end
