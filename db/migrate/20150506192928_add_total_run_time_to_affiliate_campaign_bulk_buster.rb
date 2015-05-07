class AddTotalRunTimeToAffiliateCampaignBulkBuster < ActiveRecord::Migration
  def self.up
    add_column :affiliate_campaign_bulk_busters, :total_run_time, :string, :null => true
  end

  def self.down
    remove_column :affiliate_campaign_bulk_busters, :total_run_time
  end
end
