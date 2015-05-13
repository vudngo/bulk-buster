class AffiliateCampaignBulkBuster < Buster
  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)
    create_affiliate_campaigns(api_token)
  end


  def create_affiliate_campaigns(api_token)

    # Set up Campaign Logger
    files = Briefcase.new(self.input_filename)

    # Read input file as an array of hashes
    affiliate_campaigns_hash = files.parse_input_file(self.input_filename).uniq

    # -------- #
    # The Loop #
    # -------- #

    tries_available = 3
    wait_time = 2

    affiliate_campaigns_hash.each do |campaign|

      try = 0

      puts "Joining a campaign..."

      begin
        this = Invoca::AffiliateCampaign.new(self.network_id.to_s,campaign[:affiliate_id_from_network], campaign[:affiliate_campaign_id_from_network], api_token)

        response = this.create(campaign[:advertiser_id_from_network], campaign[:advertiser_campaign_id_from_network])

        if response.code.to_s == '200' || response.code.to_s == '201'
          campaign[:status] = "success"

          this.pull_promo_numbers(campaign[:quantity]) if campaign[:quantity]

        else
          campaign[:status] = JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
        end

      rescue => error
        if try >= tries_available
          puts "Skipping this campaign"
          campaign[:status] = "unspecified error"
          files.log(campaign)
          next
        end

        try += 1
        puts "Error: " + error.to_s
        puts "Retry number #{try} of #{tries_available}"
      end

      files.log(campaign)
      sleep wait_time
    end # of the loop

    files.save

  end

end
