FactoryBot.define do
  factory :quick_menu do
    account
    name { 'Support options' }
    body { 'How can we help?' }
    items { [{ title: 'Billing' }, { title: 'Technical help' }] }
  end
end
