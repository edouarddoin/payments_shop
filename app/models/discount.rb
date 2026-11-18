class Discount < ApplicationRecord
    validates :code, presence: true, uniqueness: true
    validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :max_use_per_order, presence: true, numericality: { greater_than_or_equal_to: 1 }
end
