class AddCvvResultToSpreeCreditCards < ActiveRecord::Migration
  def change
    add_column :spree_credit_cards, :cvv_result, :string
  end
end
