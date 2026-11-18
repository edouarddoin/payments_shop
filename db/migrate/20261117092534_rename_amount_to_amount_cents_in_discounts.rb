class RenameAmountToAmountCentsInDiscounts < ActiveRecord::Migration[7.0]
  def change
    add_column :discounts, :max_user_per_user, :integer, default: 1
  end
end
