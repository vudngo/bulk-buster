class AdvertiserBulkBuster < Buster

  #has_attached_file :attachment

  validates   :input_filename, :task_description, :network_id, :presence => true
  validates   :input_filename, :uniqueness => true

  def bust(api_token)

    puts "Advertiser is about to bust...."
    create_advertisers(api_token)
  end
end


def create_advertisers(api_token)

  puts "Advertiser is busting!"

  # Setup logging to write output file
  files = Briefcase.new("#{self.class.name}_#{self.id}_#{self.description}")

  advertisers_hash = files.parse_input_file(self.input_filename)

  tries_available = 3
  wait_time = 2

  advertisers_hash.each do |advertiser|

    try = 0

    if advertiser[:advertiser_id_from_network].nil?
      advertiser[:status] = "Advertiser ID From Network cannot be blank"
      files.log(advertiser)
      next
    end

    this = Invoca::Advertiser.new(self.network_id.to_s, advertiser[:advertiser_id_from_network], api_token)

    begin
      puts "\n\nCreating advertiser with ID: " + advertiser[:advertiser_id_from_network]

      response = advertiser[:approval_status] ? this.create(advertiser[:advertiser_name], advertiser[:approval_status]) : this.create(advertiser[:advertiser_name])

      if response.code.to_s == '200' || response.code.to_s == '201'
        advertiser[:status] = "success"
      else
        advertiser[:status] = JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
      end

    rescue => e
      try += 1
      if try > tries_available
        puts "Retry limit has exceeded, skipping this advertiser"
        advertiser[:status] = e.to_s
        files.log(advertiser)
        next
      end
      puts "Retry #{try} of #{tries_available}"
      puts e.to_s
      sleep wait_time
      retry
    end

    files.log(advertiser)

  end

  files.save

end

