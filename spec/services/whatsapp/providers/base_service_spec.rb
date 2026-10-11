require 'rails_helper'

RSpec.describe Whatsapp::Providers::BaseService do
  it 'provides a valid section label when the current locale has no translation' do
    items = Array.new(4) { |index| { 'title' => "Option #{index + 1}", 'value' => "option_#{index + 1}" } }
    message = instance_double(Message, content_attributes: { 'items' => items }, outgoing_content: 'Choose')

    I18n.with_locale(:es) do
      payload = described_class.allocate.create_list_payload(message)
      action = JSON.parse(payload[:action])
      expect(action['sections'].first['title']).to eq('Options')
      expect(action['button'].length).to be <= 20
      expect(action['sections'].first['rows']).to eq(items.map { |item| { 'id' => item['value'], 'title' => item['title'] } })
    end
  end
end
