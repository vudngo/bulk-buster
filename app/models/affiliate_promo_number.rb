class AffiliatePromoNumber < Buster
  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)
    create_affiliate_promo_numbers(api_token)
  end

  def create_affiliate_promo_numbers(api_token)
    # Set up Campaign Logger
    files = Briefcase.new("#{self.class.name}_#{self.id}_#{self.description}")

    promo_numbers = files.parse_input_file(self.input_filename)

    promo_numbers.each do |promo_number|
      this = Invoca::AffiliateCampaign.new(self.network_id.to_s, promo_number[:advertiser_id_from_network], promo_number[:advertiser_campaign_id_from_network], promo_number[:affiliate_id_from_network], api_token)
      promo_number[:numbers_pulled] = this.pull_promo_numbers(promo_number[:quantity], promo_number[:media_type], promo_number[:description] )

      files.log(promo_number)

      sleep 1

    end

    files.save
  end

end
