class AdvertiserRingPoolBulkBuster < Buster

  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true



  def bust(api_token)
    create_advertiser_ring_pools(api_token)
  end
end


def create_advertiser_ring_pools(api_key)
  
  files = Briefcase.new(self.task_description)
  ring_pools = files.parse_input_file(self.input_filename)

  tries_available = 3
  wait_time = 1

  ring_pools.each do |ring_pool|

    if blanks = find_blanks(ring_pool)
      puts "\n\n" + blanks.to_s + " can't be empty"

      ring_pool[:status] = blanks.to_s + " can't be empty"
      files.log(ring_pool)
      next
    end

    try = 0
    this = Invoca::AdvertiserCampaign.new(self.network_id, ring_pool[:advertiser_id_from_network], ring_pool[:advertiser_campaign_id_from_network], api_key )

    begin
      puts "\n\nCreating RingPool named: #{ring_pool[:name]}"
      response = this.create_ring_pool(ring_pool)

      ring_pool[:status] = (response.code.to_s == '200' || response.code.to_s == '201') ? "success" : JSON.parse(response.body, :symbolize_names => true)[:errors].to_s

    rescue => e
      try += 1
      if try > tries_available
        puts "Skipping this RingPool."
        ring_pool[:status] = e.to_s
        files.log(ring_pool)
        next
      end
      puts e.inspect
      puts "Retry #{try} out of #{tries_available}"
      sleep wait_time
      retry
    end

    files.log(ring_pool)
  end

  files.save

end