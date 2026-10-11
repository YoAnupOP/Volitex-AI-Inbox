class QuickMenu < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :body, presence: true, length: { maximum: 1024 }
  validate :validate_items

  private

  def validate_items
    unless valid_item_count?
      errors.add(:items, 'must contain between 1 and 10 items')
      return
    end

    items.each_with_index { |item, index| validate_item(item, index) }
    titles = items.filter_map { |item| normalized_title(item) }
    errors.add(:items, 'titles must be unique') unless titles.uniq.length == titles.length
  end

  def valid_item_count?
    items.is_a?(Array) && items.length.between?(1, 10)
  end

  def validate_item(item, index)
    title = item_title(item, index)
    return unless title

    title_limit = items.length <= 3 ? 20 : 24
    errors.add(:items, "item #{index + 1} title must be at most #{title_limit} characters") if title.length > title_limit
  end

  def item_title(item, index)
    unless item.is_a?(Hash) && item.keys.map(&:to_s).sort == ['title']
      errors.add(:items, "item #{index + 1} must contain only a title")
      return nil
    end

    title = item['title'] || item[:title]
    return title if title.is_a?(String) && title.present?

    errors.add(:items, "item #{index + 1} title must be a non-blank string")
    nil
  end

  def normalized_title(item)
    return unless item.is_a?(Hash)

    title = item['title'] || item[:title]
    return unless title.is_a?(String) && title.present?

    title.unicode_normalize(:nfkc).strip.gsub(/\s+/, ' ').downcase
  end
end
