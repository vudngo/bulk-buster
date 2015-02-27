class CreateAffiliateCampaignBulkBusters < ActiveRecord::Migration
  def change
    create_table :affiliate_campaign_bulk_busters do |t|
      t.string :task_description,           null: false
      t.string :network_id,                 null: false
      t.string :input_filename,             null: false
      t.integer :percent_completed,         null: false, default: 0

      t.timestamps null: false
    end
  end
end
