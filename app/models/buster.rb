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
    :affiliate_payout]

ADVERTISER_ATTRIBUTES = {
    :name => "",
    :approval_status => "Approved",
    :default_creative_id_from_network => ""}

AFFILIATE_CAMPAIGN_ATTRIBUTES = {
    :status => "Applied",
    :affiliate_campaign_id_from_network => ""}

PROMO_NUMBER_ATTRIBUTES = { :description => "",
                 :media_type => "Online: Display"
}
#$LOG = Logger.new("#{NETWORK_NAME}_#{Date.today.to_s}.log")

class Buster < ActiveRecord::Base
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
      csv = CSV.new(File.open("/Users/vu/practice_code/bulk_buster/public/output/" + filename).read, :headers => true, :header_converters => :symbol)
      file_hash = csv.to_a.map {|row| row.to_hash }
    rescue
      return {}
    end
  end

  def create_advertisers(advertisers_hash, api_token)
    i = 0
    advertisers_hash.each do |advertiser|
      begin
        advertiser_body = build_advertiser_body(advertiser)
        puts advertiser_body
        create_advertiser(advertiser[:advertiser_id_from_network], advertiser_body, api_token)
          #print "."
          #sleep 2
      rescue
        i += 1
        if i > MAX_RETRY_COUNT
          puts "retry limit has exceeded"
          return false
        end
        puts "retry #{i}"
        sleep 2
        retry
      end
    end
  end
  
  def create_advertiser(adv_id, body, api_token)
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + adv_id.to_s + ".json"
    #url = "http://requestb.in/17z6g681?network_id=#{self.network_id}&advertiser_id_from_network=#{adv_id}"
    invoca_post_request(url, body, api_token)
  end

  def create_campaigns_by_cloning(campaigns_hash, api_token, campaign_terms)
    revision_type = get_campaign_terms_revision_type(campaign_terms)
    i = 0
    File.open(Rails.root.join(OUTPUT_DIRECTORY,  "campaign_bulk_output_#{self.id}.csv") , 'wb') do |f|
      f.write ['advertiser_id_from_network', 'campaign_id_from_network', 'name', 'destination_phone_number', 'url', 'status_code', 'error_message'].to_csv
      campaigns_hash.each do |campaign_inputs|
        #begin
        t = Time.now
        campaign_body = build_campaign_body_by_cloning(revision_type, campaign_terms, campaign_inputs)
        response = create_campaign(campaign_inputs[:advertiser_id_from_network], campaign_inputs[:campaign_id_from_network], api_token, campaign_body)
        if response.code.to_s == '200' || response.code.to_s == '201'
          campaign_go_live(campaign_inputs[:advertiser_id_from_network], campaign_inputs[:campaign_id_from_network], api_token)
          f.write [campaign_inputs[:advertiser_id_from_network], campaign_inputs[:campaign_id_from_network], campaign_inputs[:name], campaign_inputs[:destination_phone_number], campaign_inputs[:url], response.code, ""].to_csv
        else
          f.write [campaign_inputs[:advertiser_id_from_network], campaign_inputs[:campaign_id_from_network], campaign_inputs[:name], campaign_inputs[:destination_phone_number], campaign_inputs[:url], response.code, JSON.parse(response.body, :symbolize_names => true)[:errors].to_json].to_csv
        end

        puts Time.now - t
        sleep 2
        #print "."
        #sleep 2
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

