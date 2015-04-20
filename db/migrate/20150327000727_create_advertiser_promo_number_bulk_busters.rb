class CreateAdvertiserPromoNumberBulkBusters < ActiveRecord::Migration
  def change
    create_table :advertiser_promo_number_bulk_busters do |t|
      t.string :task_description
      t.integer :network_id
      t.string :input_filename
      t.string :output_filename
      t.string :request_type

      t.timestamps null: false
    end
  end
end
