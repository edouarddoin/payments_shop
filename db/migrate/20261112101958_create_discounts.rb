class CreateDiscounts < ActiveRecord::Migration[7.0]
  def change
    create_table :discounts do |t|
      t.string :code
      t.money :amount
      t.integer :max_use

      t.timestamps
    end
  end
end
