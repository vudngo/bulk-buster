class CampaignBulkBuster < Buster
  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)
    t = Time.now

    if  advertiser_id_from_network_to_clone.empty? || campaign_id_from_network_to_clone.empty?
        #puts "\n\nHAS NO CAMPAIGN ID: #{self.campaign_id_from_network_to_clone}\n\n"
      bust_by_input_file(api_token)
    else
      #puts "\n\nHAS CAMPAIGN ID: #{self.campaign_id_from_network_to_clone}\n\n"
      bust_by_cloning(api_token)
    end

    self.total_run_time =  Time.at(Time.now - t).utc.strftime("%H:%M:%S")
    self.save
  end

  def bust_by_input_file(api_token)
    return true
  end

  def bust_by_cloning(api_token)
    #file_hash = []
    file_hash = parse_input_file(self.input_filename)
    duplicates = file_hash.select{|item| file_hash.count(item) > 1}.uniq

    #puts "Duplicate Count:" + file_hash.count.to_s
    #puts "Duplicate Count:" + duplicates.count.to_s
    #puts file_hash.uniq[0, 1]
    campaign_terms = get_campaign_terms_to_clone(api_token)
    #puts "* Terms to Clone *"
    #puts campaign_terms[:future_terms][:named_regions]
    #puts campaign_terms[:current_terms][:named_regions]
    create_campaigns_by_cloning(file_hash.uniq, api_token, campaign_terms)
  end
end
