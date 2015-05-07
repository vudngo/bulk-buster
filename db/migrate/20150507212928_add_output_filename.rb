class AddOutputFilename < ActiveRecord::Migration
  def self.up
    add_column :advertiser_bulk_busters, :output_filename, :string, :null => true
    add_column :campaign_bulk_busters, :output_filename, :string, :null => true
    add_column :affiliate_campaign_bulk_busters, :output_filename, :string, :null => true
  end

  def self.down
    remove_column :advertiser_bulk_busters, :output_filename
    remove_column :campaign_bulk_busters, :output_filename
    remove_column :affiliate_campaign_bulk_busters, :output_filename
  end
end
