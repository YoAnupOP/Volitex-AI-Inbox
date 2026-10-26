require 'rails_helper'
require 'crass'

RSpec.describe Crass::Tokenizer do
  it 'terminates bad URLs after escaped backslashes instead of swallowing live CSS' do
    backslashes = 92.chr * 2
    prefix = "url(x\"#{backslashes})"
    tokens = described_class.tokenize("#{prefix}after").map { |token| [token[:node], token[:raw]] }
    expect(tokens).to eq([[:bad_url, prefix], [:ident, 'after']])
  end
end
