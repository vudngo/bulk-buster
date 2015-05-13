class CreateAffiliatePromoNumbers < ActiveRecord::Migration
  def change
    create_table :affiliate_promo_numbers do |t|
      t.string :task_description
      t.string :network_id
      t.string :input_filename
      t.string :output_filename

      t.timestamps null: false
    end
  end
end
