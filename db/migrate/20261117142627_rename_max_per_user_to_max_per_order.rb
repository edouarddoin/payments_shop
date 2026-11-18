class RenameMaxPerUserToMaxPerOrder < ActiveRecord::Migration[7.0]
  def change
    rename_column :discounts, :max_use, :max_use_per_order
  end
end
