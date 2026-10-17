## we had instances where after copy pasting the schedule block,
## the dev forgets to changes the schedule key,
## this would break some of the scheduled jobs with out explicit errors
require 'rails_helper'

RSpec.context 'with valid schedule.yml' do
  it 'does not have duplicates' do
    file = Rails.root.join('config/schedule.yml')
    # Read the syntax tree: loading a Hash would silently discard duplicate keys.
    schedule_keys = Psych.parse_file(file).root.children.each_slice(2).map { |key, _value| key.value }
    # ensure that no duplicates exist
    expect(schedule_keys.count).to eq(schedule_keys.uniq.count)
  end
end
