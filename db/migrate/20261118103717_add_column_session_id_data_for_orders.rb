class AddColumnSessionIdDataForOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :checkout_session_data, :text
  end
end
