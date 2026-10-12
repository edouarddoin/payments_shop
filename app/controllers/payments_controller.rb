class PaymentsController < ApplicationController
  def new
    @order = current_user.orders.where(status_id: 1).find(params[:order_id])
  end
end
