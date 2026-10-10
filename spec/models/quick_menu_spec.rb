require 'rails_helper'

RSpec.describe QuickMenu do
  subject(:quick_menu) { described_class.new(account: create(:account), name: 'Support', body: 'Choose an option', items: items) }

  let(:items) { [{ title: 'Billing' }, { title: 'Technical help' }] }

  it 'accepts reply button titles up to 20 characters' do
    quick_menu.items = [{ title: 'x' * 20 }]
    expect(quick_menu).to be_valid
  end

  it 'accepts list row titles up to 24 characters' do
    quick_menu.items = Array.new(4) { |index| { title: "#{index}#{'x' * 23}" } }
    expect(quick_menu).to be_valid
  end

  it 'requires a name, non-blank body of at most 1,024 characters, and 1–10 items' do
    quick_menu.name = ''
    quick_menu.body = ' '
    quick_menu.items = []
    expect(quick_menu).not_to be_valid

    quick_menu.name = 'Support'
    quick_menu.body = 'x' * 1025
    quick_menu.items = Array.new(11) { |index| { title: "Item #{index}" } }
    expect(quick_menu).not_to be_valid
  end

  it 'rejects malformed items, non-string titles, and titles over the provider limit' do
    quick_menu.items = ['Billing']
    expect(quick_menu).not_to be_valid

    quick_menu.items = [{ title: 12 }]
    expect(quick_menu).not_to be_valid

    quick_menu.items = [{ title: 'x' * 21 }]
    expect(quick_menu).not_to be_valid
  end

  it 'rejects duplicate titles after Unicode normalization, whitespace folding, and case folding' do
    quick_menu.items = [{ title: 'Help Desk' }, { title: "  help\u00a0desk " }]
    expect(quick_menu).not_to be_valid
  end
end
