class AddTotalRunTimeToAdvertiserRingPoolBulkBuster < ActiveRecord::Migration
  def self.up
    add_column :advertiser_ring_pool_bulk_busters, :total_run_time, :string, :null => true
  end

  def self.down
    remove_column :advertiser_ring_pool_bulk_busters, :total_run_time
  end
end
