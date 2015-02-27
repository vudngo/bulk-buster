class CreateCampaignBulkBusters < ActiveRecord::Migration
  def change
    create_table :campaign_bulk_busters do |t|
      t.string  :task_description,                      null: false
      t.string  :network_id,                            null: false
      t.string  :advertiser_id_from_network_to_clone,   null: true
      t.string  :campaign_id_from_network_to_clone,     null: true
      t.string  :input_filename,                        null: false
      t.integer :percent_completed,                     null: false, default: 0

      t.timestamps null: false
    end
  end
end
