class Discount < ApplicationRecord
    monetize :amount_cents
end
