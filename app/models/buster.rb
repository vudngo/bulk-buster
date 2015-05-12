require 'csv'
require 'logger'
require 'net/http'

ROOT_DIR =

MAX_RETRY_COUNT = 2
OUTPUT_DIRECTORY = 'public/output'
HTTP_CONTENT_TYPE = 'application/json'

NETWORK_DOMAIN = 'https://invoca.net'
#NETWORK_DOMAIN = 'https://invocasandbox.com'


AFFILIATE_CAMPAIGN_ATTRIBUTES = {
    :status => "Applied",
    :affiliate_campaign_id_from_network => ""
}

PROMO_NUMBER_ATTRIBUTES = {
    :description => "",
    :media_type => "Online: Display"
}

class Buster < ActiveRecord::Base

  # include Modules::ObjectBuilding

  self.abstract_class = true


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





  def update_advertiser_promo_number(promo_number, api_token)
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



  def build_affiliate_campaign_body(affiliate_campaign)
    affiliate_campaign_body = AFFILIATE_CAMPAIGN_ATTRIBUTES
    affiliate_campaign_body[:affiliate_campaign_id_from_network] = affiliate_campaign[:campaign_id_from_network].to_s + affiliate_campaign[:affiliate_id_from_network].to_s
    affiliate_campaign_body
  end



  def build_ring_pool_body(ring_pool)
    ring_pool_body = ring_pool.clone
    ring_pool_body.delete(:advertiser_id_from_network)
    ring_pool_body.delete(:advertiser_campaign_id_from_network)
    ring_pool_body.delete(:ringpool_id_from_network)
    return ring_pool_body
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
