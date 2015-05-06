require 'csv'
require 'logger'
require 'net/http'

ROOT_DIR = Rails.root.to_s

MAX_RETRY_COUNT = 2
OUTPUT_DIRECTORY = 'public/output'
HTTP_CONTENT_TYPE = 'application/json'

NETWORK_DOMAIN = 'https://invoca.net'
#NETWORK_DOMAIN = 'https://invocasandbox.com'
CAMPAIGN_ATTRIBUTE_KEYS = [
    :name,
    :description,
    :url,
    :operating_24_7,
    :visibility,
    :campaign_type,
    :expiration_date,
    :timezone,
    :auto_approve,
    :hours,
    #:named_regions,
    :url,
    :ivr_tree,
    :advertiser_payin,
    :affiliate_payout
]

ADVERTISER_ATTRIBUTES = {
    :name => "",
    :approval_status => "Approved",
    :default_creative_id_from_network => ""
}

AFFILIATE_CAMPAIGN_ATTRIBUTES = {
    :status => "Applied",
    :affiliate_campaign_id_from_network => ""
}

PROMO_NUMBER_ATTRIBUTES = {
    :description => "",
    :media_type => "Online: Display"
}

#$LOG = Logger.new("#{NETWORK_NAME}_#{Date.today.to_s}.log")

class Buster < ActiveRecord::Base

  # include Modules::ObjectBuilding

  self.abstract_class = true

  def invoca_get_request(url, api_token)
    uri = URI(url)
    params = { :oauth_token => api_token}
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new(uri.to_s)
      response = http.request request
      if response.code.to_s != '200' && response.code.to_s != '201'
        puts url
        #$LOG.error url + " - " + response.code.to_s + " - " + response.body
      end
      return response
    end
  end

  def invoca_post_request(url, body, api_token)
    uri = URI(url)
    params = { :oauth_token =>  api_token}
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new(uri.to_s)
      request["Content-Type"] = HTTP_CONTENT_TYPE
      request.body = body.to_json
      response = http.request request
      puts response.code
      #puts response.body
      if response.code.to_s != '200' && response.code.to_s != '201'
        puts url
        #$LOG.error url + " - " + response.code.to_s + " - " + response.body
      end
      return response
    end
  end

  def invoca_put_request(url, body, api_token)
    uri = URI(url)
    params = { :oauth_token =>  api_token}
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Put.new(uri.to_s)
      request["Content-Type"] = HTTP_CONTENT_TYPE
      request.body = body.to_json
      response = http.request request
      puts response.code
      #puts response.body
      if response.code.to_s != '200' && response.code.to_s != '201'
        puts url
        #$LOG.error url + " - " + response.code.to_s + " - " + response.body
      end
      return response
    end
  end


  def parse_input_file(filename)
    csv = CSV.new(File.open(ROOT_DIR + "/public/uploads/" + filename).read, :headers => true, :header_converters => :symbol)
    file_hash = csv.to_a.map {|row| row.to_hash }
    return file_hash
  end

  def parse_output_file(filename)
    begin
      csv = CSV.new(File.open( ROOT_DIR + "/public/output/" + filename).read, :headers => true, :header_converters => :symbol)
      file_hash = csv.to_a.map {|row| row.to_hash }
    rescue
      return {}
    end
  end


  def write_output_file(logfile, filename, headers = true, format = "hash")

    print "Writing ouput file..."


    if format == "hash"

      CSV.open(Rails.root.join(OUTPUT_DIRECTORY, filename), "wb") do |csv|
        csv << logfile.first.keys if headers
        logfile.each do |hash|
          csv << hash.values
        end
      end

    elsif format == "string"

      File.open(Rails.root.join(OUTGOING_FTP_DIRECTORY, filename),'w') do |f|
        logfile.each do |call|
          f.write(call + "\n")
        end
      end

    end

    print " complete.\n\n"


  end


  def create_advertisers(advertisers_hash, api_token)

    # Setup logging to write output file
    filename = "advertiser_output_#{self.id}.csv"
    logfile  = []
    total_busted = 0
    start_time = Time.now

    advertisers_hash.each do |advertiser|

      i = 0
      begin
        puts "\n\nCreating advertiser with ID: " + advertiser[:advertiser_id_from_network]

        advertiser_body = build_advertiser_body(advertiser)
        puts advertiser_body
        response = create_advertiser(advertiser[:advertiser_id_from_network], advertiser_body, api_token)
        advertiser[:status] = response.code.to_s

        puts "Received HTTP status: " + advertiser[:status]

        if response.code.to_s == '200' || response.code.to_s == '201'
          advertiser[:error] = "none"
        else
          advertiser[:error] = JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
        end

      rescue
        i += 1
        if i > MAX_RETRY_COUNT
          puts "Retry limit has exceeded"
          return false
        end
        puts "Retry #{i}"
        sleep 2
        retry
      end

      logfile << advertiser
      total_busted += 1

    end

    puts "\n\nBusting Complete"
    puts "-----------------------------"
    puts "Total busted: #{total_busted}"
    puts "Time Elapsed: " + (Time.now - start_time).to_s
    puts "-----------------------------\n\n"

    write_output_file(logfile, filename)

  end


  def create_advertiser(adv_id, body, api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + adv_id.to_s + ".json"
    #url = "http://requestb.in/17z6g681?network_id=#{self.network_id}&advertiser_id_from_network=#{adv_id}"
    invoca_post_request(url, body, api_token)
  end


  def create_campaigns_by_cloning(campaigns_hash, api_token, campaign_terms)

    # Setup logging to write output file
    # Setup logging to write output file
    description = self.task_description.gsub!(/[!@%&"]/,'-')
    filename = "#{description}--campaign_output_#{self.id}.csv"
    logfile  = []
    total_busted = 0
    start_time = Time.now

    revision_type = get_campaign_terms_revision_type(campaign_terms)

      campaigns_hash.each do |campaign_inputs|

        i = 0

        begin

          puts "\n\nCloning into campaign: " + campaign_inputs[:name].to_s

          t = Time.now
          campaign_body = build_campaign_body_by_cloning(revision_type, campaign_terms, campaign_inputs)
          campaign_body[:ivr_tree] = replace_destination_numbers(campaign_body,campaign_inputs)
          response = create_campaign(campaign_inputs[:advertiser_id_from_network], campaign_inputs[:advertiser_campaign_id_from_network], api_token, campaign_body)

          if response.code.to_s == '200' || response.code.to_s == '201'
            campaign_inputs[:error] = "none"
            campaign_go_live(campaign_inputs[:advertiser_id_from_network],campaign_inputs[:campaign_id_from_network], api_token)
          else
            campaign_inputs[:error] = JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
          end

          puts "Time for this campaign: " + (Time.now - t).to_s

        rescue => e
          i += 1
          if i > MAX_RETRY_COUNT
            puts "Retry limit has exceeded"
            return false
          end
          puts "Retry: #{i}"
          puts e
          sleep 2
          retry
        end

        # Update logging
        logfile << campaign_inputs
        total_busted += 1

        sleep 2

      end


    puts "\n\nBusting Complete"
    puts "-----------------------------"
    puts "Total busted: #{total_busted}"
    puts "Time Elapsed: " + (Time.now - start_time).to_s
    puts "-----------------------------\n\n"

    write_output_file(logfile, filename)

  end

  def replace_destination_numbers(campaign_body, campaign_inputs)


    def build_mapping(inputs)

      i = 0
      defaults = ["800-444-1111", "800-444-2222", "800-444-3333", "800-444-4444", "800-444-5555"]
      mapping = []

      while inputs["destination_phone_number_#{i+1}".to_sym]
        mapping << [defaults[i], inputs["destination_phone_number_#{i+1}".to_sym] ]
        i += 1
      end

      return mapping

    end

    ivr = campaign_body[:ivr_tree]
    ivr_string = ivr.to_s

    puts "\n\n"
    print "Updating destinations:"

    mapping = build_mapping(campaign_inputs)

    mapping.each do |d|
      replace = d[0].to_s.gsub("-","")
      with = d[1].to_s.gsub("-","")
      updated = ivr_string.gsub(replace,with)
      ivr_string = updated
      print "."
    end

    puts "\nDone.\n\n"
    ivr = eval ivr_string

    campaign_body[:ivr_tree] = ivr

  end



  def create_campaign(adv_id, campaign_id, api_token, body)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id + "/advertisers/" + adv_id.to_s + "/advertiser_campaigns/" + campaign_id.to_s + ".json"
    invoca_post_request(url, body, api_token)
  end

  def create_affiliate_campaigns(affiliate_campaigns_hash, api_token)
    i = 0
    affiliate_campaigns_hash.each do |affiliate_campaign|
      #begin
        affiliate_campaign_body = build_affiliate_campaign_body(affiliate_campaign)
        puts affiliate_campaign
        create_affiliate_campaign(affiliate_campaign[:advertiser_id_from_network], affiliate_campaign[:campaign_id_from_network], affiliate_campaign[:affiliate_id_from_network], affiliate_campaign_body, api_token)
        promo_number_body = build_promo_number_body(affiliate_campaign)
        create_affiliate_promo_number(affiliate_campaign[:advertiser_id_from_network], affiliate_campaign[:campaign_id_from_network], affiliate_campaign[:affiliate_id_from_network], promo_number_body, api_token)
      # rescue
      #   i += 1
      #   if i > MAX_RETRY_COUNT
      #     puts "retry limit has exceeded"
      #     return false
      #   end
      #   puts "retry #{i}"
      #   sleep 2
      #   retry
      # end
    end
  end

  def create_affiliate_campaign(adv_id, campaign_id, affiliate_id, body, api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + adv_id.to_s + "/advertiser_campaigns/" + campaign_id.to_s + "/affiliates/" + affiliate_id.to_s + "/affiliate_campaigns.json"
    invoca_post_request(url, body, api_token)
  end

  def create_advertiser_ring_pools(ring_pool_hash, api_token)
    i = 0
    ring_pool_hash.each do |ring_pool|
      #begin
         puts ring_pool
         create_advertiser_ring_pool(ring_pool, api_token)
      # rescue
      #   i += 1
      #   if i > MAX_RETRY_COUNT
      #     puts "retry limit has exceeded"
      #     return false
      #   end
      #   puts "retry #{i}"
         sleep 0.5
      #   retry
      # end
    end
  end

  def create_advertiser_ring_pool(ring_pool, api_token)
    #puts "in create functions"
    ring_pool_body = build_ring_pool_body(ring_pool)
    #puts "RingPool Body:"
    #puts ring_pool_body
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + ring_pool[:advertiser_id_from_network].to_s + "/advertiser_campaigns/" + ring_pool[:advertiser_campaign_id_from_network].to_s + "/ring_pools/" + ring_pool[:ringpool_id_from_network].to_s + ".json"
    #puts "URL: #{url}"
    invoca_post_request(url, ring_pool_body, api_token)
  end

  def update_advertiser_promo_numbers(promo_number_hash, api_token)
    i = 0
    promo_number_hash.each do |promo_number|
      #begin
      #puts promo_number
      update_advertiser_promo_number(promo_number, api_token)
      # rescue
      #   i += 1
      #   if i > MAX_RETRY_COUNT
      #     puts "retry limit has exceeded"
      #     return false
      #   end
      #   puts "retry #{i}"
      sleep 0.5
      #   retry
      # end
    end
  end

  def create_advertiser_promo_numbers(promo_number_hash, api_token)

    # Setup logging to write output file
    description = self.task_description.gsub!(/[!@%&"]/,'-')
    filename = "#{description}--campaign_output_#{self.id}.csv"
    logfile  = []
    total_busted = 0
    start_time = Time.now

    i = 0
    promo_number_hash.each do |promo_number|

      promo_number[:numbers_pulled] = pull_promo_numbers(promo_number, api_token)

      # Update logging
      logfile << promo_number
      total_busted += 1

      sleep 2

    end

    puts "\n\nBusting Complete"
    puts "-----------------------------"
    puts "Total busted: #{total_busted}"
    puts "Time Elapsed: " + (Time.now - start_time).to_s
    puts "-----------------------------\n\n"

    write_output_file(logfile, filename)

  end

  # Pull however many numbers are requested
  def pull_promo_numbers(campaign, api_token)


    numbers_needed = campaign[:quantity].to_i || 1
    numbers_pulled = ""

    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + campaign[:advertiser_id_from_network].to_s + "/advertiser_campaigns/" + campaign[:advertiser_campaign_id_from_network].to_s + "/promo_numbers.json"
    body = {
        :description => "Created on " + Time.now.strftime("%m/%d/%Y %H:%M"),
        :media_type  => "Online: Display"
    }

    while numbers_needed > 0

      response = invoca_post_request(URI.encode(url), body, api_token)
      details = response.to_json

      if response
        details = JSON.parse(response.body)
        if numbers_needed == campaign[:quantity].to_i
          numbers_pulled += details['promo_number']
        else
          numbers_pulled += "|" + details['promo_number']
        end
      end

      numbers_needed -= 1
    end

    return numbers_pulled

  end

  def update_advertiser_promo_number(promo_number, api_token)
    #puts "in create functions"
    promo_number_body = build_promo_number_body(promo_number)
    puts "Promo Number Body:"
    puts promo_number_body
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + promo_number[:advertiser_id_from_network].to_s + "/advertiser_campaigns/" + promo_number[:advertiser_campaign_id_from_network].to_s + "/promo_numbers/" + promo_number[:promo_number].to_s + ".json"
    puts "URL: #{url}"
    invoca_put_request(url, promo_number_body, api_token)
  end

  def create_affiliate_promo_number(adv_id, campaign_id, affiliate_id, body, api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + adv_id.to_s + "/advertiser_campaigns/" + campaign_id.to_s + "/affiliates/" + affiliate_id.to_s + "/affiliate_campaigns/promo_numbers.json"
    invoca_post_request(url, body, api_token)
  end

  def build_advertiser_body(advertiser)
    advertiser_body = ADVERTISER_ATTRIBUTES
    advertiser_body[:name] = advertiser[:advertiser_name]
    advertiser_body[:default_creative_id_from_network] = advertiser[:advertiser_id_from_network]
    advertiser_body[:approval_status] = advertiser[:approval_status].capitalize
    advertiser_body
  end

  def build_campaign_body_by_cloning(revision_type, campaign_terms, campaign_inputs)
    campaign_body = {}
    CAMPAIGN_ATTRIBUTE_KEYS.each do |key|
      if key != :name
        campaign_body[key] = campaign_terms[revision_type][key]
      end
    end

    if campaign_inputs[:url]
      campaign_body[:url] = campaign_inputs[:url]
    end

    campaign_body[:name] = campaign_inputs[:name]
    campaign_body[:ivr_tree][:root][:destination_phone_number] = campaign_inputs[:destination_phone_number]

    return campaign_body
  end

  def build_affiliate_campaign_body(affiliate_campaign)
    affiliate_campaign_body = AFFILIATE_CAMPAIGN_ATTRIBUTES
    affiliate_campaign_body[:affiliate_campaign_id_from_network] = affiliate_campaign[:campaign_id_from_network].to_s + affiliate_campaign[:affiliate_id_from_network].to_s
    affiliate_campaign_body
  end

  def build_promo_number_body(promo_number)
    promo_number_body = PROMO_NUMBER_ATTRIBUTES
    promo_number_body[:description] = promo_number[:description]
    promo_number_body[:media_type] = promo_number[:media_type]
    promo_number_body
  end

  def build_ring_pool_body(ring_pool)
    ring_pool_body = ring_pool.clone
    ring_pool_body.delete(:advertiser_id_from_network)
    ring_pool_body.delete(:advertiser_campaign_id_from_network)
    ring_pool_body.delete(:ringpool_id_from_network)
    return ring_pool_body
  end

  def get_campaign_terms_to_clone(api_token)
    response = get_campaign_terms(api_token)
    if response.code.to_i != 200
       puts "\n\n\n"
       puts "*******************SOMETHING FAILED**********************"
       puts response.code
       puts response.body
       puts "*********************************************************"
       puts "\n\n\n"
       return false
    end
    return JSON.parse(response.body,:symbolize_names => true)
  end

  def get_campaign_terms(api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + self.advertiser_id_from_network_to_clone.to_s+ "/advertiser_campaigns/" + self.campaign_id_from_network_to_clone.to_s + ".json"
    response = invoca_get_request(url, api_token)
    return response
  end

  def does_campaign_exist?
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + adv_id.to_s + "advertiser_campaigns/" + self.campaign_id_from_network_to_clone.to_s + ".json"
    invoca_get_request(url, api_token)
  end

  def get_campaign_terms_revision_type(campaign_terms)
    if campaign_terms[:future_terms]
      revision_type = :future_terms
    else
      revision_type = :current_terms
    end
    return revision_type
  end

  def campaign_go_live(adv_id, campaign_id, api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id + "/advertisers/" + adv_id.to_s + "/advertiser_campaigns/" + campaign_id.to_s + "/go_live.json"
    invoca_get_request(url, api_token)
  end

  def get_results(hash)
    result_array = hash.map {|h| h[:status_code]}
    result_hash = {}

    result_array.each do |result|
      if result_hash[result].nil?
        result_hash[result] = 1
      else
        result_hash[result] += 1
      end
    end
    return result_hash
  end

end