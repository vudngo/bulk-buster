class CreateBulkTrackers < ActiveRecord::Migration
  def change
    create_table :bulk_trackers do |t|
      t.string :description
      t.integer :advertiser_count
      t.integer :advertiser_campaign_count
      t.integer :affiliate_count
      t.integer :affiliate_campaign_count
      t.integer :ring_pool_count
      t.integer :promo_number_count

      t.timestamps null: false
    end
  end
end
