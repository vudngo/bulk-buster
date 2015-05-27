require 'csv'
require 'logger'
require 'net/http'

OUTPUT_DIRECTORY = 'public/output'
HTTP_CONTENT_TYPE = 'application/json'

class Buster < ActiveRecord::Base

  # include Modules::ObjectBuilding

  self.abstract_class = true

  def replace_destination_numbers(campaign_body, campaign_inputs)
    puts "\n\n"
    print "Updating destinations: "

    # If there is only a direct transfer, update that single number and then leave
    if campaign_inputs[:destination_phone_number]
      print "Only found a single number.\n"
      campaign_body[:ivr_tree][:root][:destination_phone_number] = campaign_inputs[:destination_phone_number]
      return campaign_body[:ivr_tree]
    end


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

  def update_advertiser_promo_number(promo_number, api_token)
    promo_number_body = build_promo_number_body(promo_number)
    puts "Promo Number Body:"
    puts promo_number_body
    url = NETWORK_DOMAIN + "/api/2014-01-01/" + self.network_id.to_s + "/advertisers/" + promo_number[:advertiser_id_from_network].to_s + "/advertiser_campaigns/" + promo_number[:advertiser_campaign_id_from_network].to_s + "/promo_numbers/" + promo_number[:promo_number].to_s + ".json"
    puts "URL: #{url}"
    invoca_put_request(url, promo_number_body, api_token)
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
