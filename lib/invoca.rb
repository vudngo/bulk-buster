require 'net/http'
require 'net/https'
require 'net/ftp'
require 'json'
require 'csv'
require 'uri'

# The Invoca Class contains subclasses for each object
class Invoca

  # -------------- #
  # Company Object #
  # -------------- #

  class Company

    attr_accessor :network_id, :api_key

    def initialize(network_id, api_key)
      @network_id = network_id
      @api_key = api_key
    end

  end


  # ----------------- #
  # Advertiser Object #
  # ----------------- #


  class Advertiser

    # Init instance variables
    attr_accessor :network_id, :advertiser_id_from_network, :api_key


    def initialize(network_id, advertiser_id_from_network, api_key)
      @network_id = network_id
      @advertiser_id_from_network = advertiser_id_from_network
      @api_key = api_key
      @url = "https://invoca.net/api/2014-11-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + ".json"
      @http = HttpRequest.new(@api_key)
    end

    def get
      response = @http.get_request(@url)
      JSON.parse(response.body, :symbolize_names => true) if response
    end

    def create(name, approval_status = "Approved")

      advertiser_attributes = {
          :name => name,
          :approval_status => approval_status.to_s.capitalize,
          :default_creative_id_from_network => ""
      }

      @http.post_request(@url, advertiser_attributes)

    end

    def new_campaign(name, id_from_network)
      new_campaign = AdvertiserCampaign.new(@network_id, @advertiser_id_from_network, id_from_network, @api_key)
      instance_variable_set "@#{name}", new_campaign
      singleton_class.class_eval do; attr_accessor "#{name}"; end
    end

  end # End of Advertiser


  # -------------------------- #
  # Advertiser Campaign Object #
  # -------------------------- #


  class AdvertiserCampaign < Advertiser

    # Init instance variables
    attr_accessor :network_id, :advertiser_id_from_network, :id_from_network, :api_key

    @@campaign_attributes = [
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
        :url,
        :ivr_tree,
        :advertiser_payin,
        :affiliate_payout
    ]


    def initialize(network_id,advertiser_id_from_network, id_from_network, api_key)
      @network_id = network_id
      @advertiser_id_from_network = advertiser_id_from_network
      @id_from_network = id_from_network
      @api_key = api_key

      @http = HttpRequest.new(@api_key)
    end

    # Get this campaign's full body
    def get
      url = "https://invoca.net/api/2014-11-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + "/advertiser_campaigns/" + @id_from_network.to_s + ".json"
      response = @http.get_request(url)
      JSON.parse(response.body, :symbolize_names => true) if response
    end

    # Create this campaign in Invoca
    def create(body)
      url = "https://invoca.net/api/2014-11-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + "/advertiser_campaigns/" + @id_from_network.to_s + ".json"
      @http.post_request(url, body)
    end

    # Pull however many numbers are requested
    def pull_promo_numbers(quantity, media_type = "Online: Display", description = "Created on " + Time.now.strftime("%m/%d/%Y %H:%M"))

      numbers_needed = quantity.to_i || 1
      numbers_pulled = ""

      url = "https://invoca.net/api/2014-01-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + "/advertiser_campaigns/" + @id_from_network.to_s + "/promo_numbers.json"

      body = {
          :description => description,
          :media_type  => media_type
      }

      while numbers_needed > 0

        response = @http.post_request(url, body)

        if response
          details = JSON.parse(response.body)
          if numbers_needed == quantity.to_i
            numbers_pulled += details['promo_number']
          else
            numbers_pulled += "|" + details['promo_number']
          end
        end

        numbers_needed -= 1
      end

      return numbers_pulled
    end

    # Return "postable" body with only accepted attributes
    def clone(name = "Unnamed")

      original = self.get
      body = { :name => name }

      @@campaign_attributes.each do |key|
        body[key] = original[:current_terms][key] if key != :name
      end

      return body

    end

    # Go live in Invoca
    def go_live(id = nil)
      puts "Going live"
      id = @id_from_network unless id
      url = "https://invoca.net/api/2014-11-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + "/advertiser_campaigns/" + id.to_s + "/go_live.json"
      @http.get_request(url)
    end

    # Join this campaign with an affiliate campaign
    def join_with(affiliate_id_from_network, affiliate_campaign_id_from_network, status = "Approved")
      url = "https://invoca.net/api/2014-11-01/" + @network_id + "/advertisers/" + @advertiser_id_from_network + "/advertiser_campaigns/" + @id_from_network + "/affiliates/" + affiliate_id_from_network.to_s + "/affiliate_campaigns.json"
      body = {
          'status' => status,
          'affiliate_campaign_id_from_network' => affiliate_campaign_id_from_network.to_s
      }

      @http.post_request(url, body)
    end

  end # End of AdvertiserCampaign


  # ------------------------- #
  # Affiliate Campaign Object #
  # ------------------------- #


  class AffiliateCampaign < AdvertiserCampaign

    # Init
    attr_accessor :network_id, :id_from_network, :api_key


    def initialize(network_id, advertiser_id_from_network, advertiser_campaign_id_from_network, affiliate_id_from_network, api_key)
      @network_id = network_id
      @affiliate_id_from_network = affiliate_id_from_network
      @advertiser_id_from_network = advertiser_id_from_network
      @advertiser_campaign_id_from_network = advertiser_campaign_id_from_network
      @api_key = api_key

      @http = HttpRequest.new(@api_key)
    end

    def create( status = "Approved")
      url = "https://invoca.net/api/2014-11-01/" + @network_id + "/advertisers/" + @advertiser_id_from_network + "/advertiser_campaigns/" + @advertiser_campaign_id_from_network + "/affiliates/" + @affiliate_id_from_network.to_s + "/affiliate_campaigns.json"
      body = {
          'status' => status,
          'affiliate_campaign_id_from_network' => @id_from_network.to_s
      }

      @http.post_request(url, body)
    end

    def pull_promo_numbers(quantity, media_type = "Online: Display", description = "Created on " + Time.now.strftime("%m/%d/%Y %H:%M"))
      numbers_needed = quantity.to_i || 1
      numbers_pulled = ""

      url = "https://invoca.net/api/2014-01-01/" + @network_id.to_s + "/advertisers/" + @advertiser_id_from_network.to_s + "/advertiser_campaigns/" + @advertiser_campaign_id_from_network.to_s + "/affiliates/" + @affiliate_id_from_network + "/affiliate_campaigns/promo_numbers.json"

      body = {
          :description => description,
          :media_type  => media_type
      }

      while numbers_needed > 0

        response = @http.post_request(url, body)

        if response
          details = JSON.parse(response.body)
          numbers_pulled += ( numbers_needed == quantity ) ? details['promo_number'] : "|#{details['promo_number']}"
        end

        numbers_needed -= 1
      end

      return numbers_pulled
    end

  end

end
