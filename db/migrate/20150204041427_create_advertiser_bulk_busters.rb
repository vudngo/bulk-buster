class CreateAdvertiserBulkBusters < ActiveRecord::Migration
  def change
    create_table :advertiser_bulk_busters do |t|
      t.string     :task_description,  null: false
      t.integer    :network_id,        null: false
      t.string     :input_filename,    null: false
      t.integer    :percent_completed, null: false, default: 0

      t.timestamps null: false
    end
  end
end
