class CreateSpreeInstamojoCheckout < ActiveRecord::Migration[5.1]
  def change
    create_table :spree_payment_checkouts do |t|
      t.string :payment_request_id
      t.string :payment_id
      t.string :order_id
      t.string :amount
      t.string :status
      t.text :checksum
      t.timestamps
    end
  end
end
