class CampaignBulkBuster < Buster
  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)
    t = Time.now

    bust_by_cloning(api_token)

    self.total_run_time =  Time.at(Time.now - t).utc.strftime("%H:%M:%S")
    self.save
  end

  def bust_by_cloning(api_token)

    # Set up Campaign Logger
    files = Briefcase.new(self.task_description)

    # Read input file as an array of hashes
    campaign_hash = files.parse_input_file(self.input_filename).uniq

    # Create prototype campaign to be cloned
    campaign_body = Invoca::AdvertiserCampaign.new(self.network_id.to_s, self.advertiser_id_from_network_to_clone.to_s, self.campaign_id_from_network_to_clone.to_s, api_token).clone("Prototype")

    # -------- #
    # The Loop #
    # -------- #

    tries_available = 3
    wait_time = 2

    campaign_hash.each do |campaign|

      try = 0

      puts "Cloning into: #{campaign[:name].to_s}"

      begin
        this = Invoca::AdvertiserCampaign.new(self.network_id.to_s,campaign[:advertiser_id_from_network], campaign[:advertiser_id_from_network], api_token)
        new_campaign = campaign_body

        new_campaign[:name] = campaign[:name]
        new_campaign[:ivr_tree] = replace_destination_numbers(new_campaign,campaign)

        response = this.create(new_campaign)

        if response.code.to_s == '200' || response.code.to_s == '201'
          campaign[:status] = "success"

          this.pull_promo_numbers(campaign[:quantity]) if campaign[:quantity]
          this.go_live
        else
          campaign[:error] = JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
        end

      rescue => error
        if try >= tries_available
          puts "Skipping this campaign"
          campaign[:error] = "unspecified error"
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
