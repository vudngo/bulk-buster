require 'net/http'
require 'net/https'
require 'net/ftp'
require 'json'
require 'csv'
require 'uri'
require 'open-uri'


# The Invoca Class contains subclasses for each object

DOMAIN = "https://invoca.net"

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
      @url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + ".json"
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
      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(@id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + ".json"
      response = @http.get_request(url)
      JSON.parse(response.body, :symbolize_names => true) if response
    end

    # Create this campaign in Invoca
    def create(body)
      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" +URI.escape(@id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + ".json"
      @http.post_request(url, body)
    end

    # Pull however many numbers are requested
    def pull_promo_numbers(quantity, media_type = "Online: Display", description = "Created on " + Time.now.strftime("%m/%d/%Y %H:%M"))

      numbers_needed = ( quantity.nil? ) ? 1 : quantity.to_i
      numbers_pulled = ""

      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" +URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(@id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/promo_numbers.json"

      body = {
          :description => description,
          :media_type  => media_type
      }

      while numbers_needed > 0
        puts "Attempting to pull a promo number"
        response = @http.post_request(url, body)

        if response.code.to_s == '200' || response.code.to_s == '201'
          details = JSON.parse(response.body)
          if numbers_needed == quantity.to_i
            numbers_pulled += details['promo_number']
          else
            numbers_pulled += "|" + details['promo_number']
          end
        else
          puts "\n\nmedia type: " + media_type.to_s + "\n\n"
          numbers_pulled += JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
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
      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/go_live.json"
      @http.get_request(url)
    end

    # Join this campaign with an affiliate campaign
    def join_with(affiliate_id_from_network, affiliate_campaign_id_from_network, status = "Approved")
      url = DOMAIN + "/api/2015-05-01/" + @network_id + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(@aid_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/affiliates/" + URI.escape(@affiliate_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/affiliate_campaigns.json"
      body = {
          'status' => status,
          'affiliate_campaign_id_from_network' => affiliate_campaign_id_from_network.to_s
      }

      @http.post_request(url, body)
    end

    def create_ring_pool(ring_pool)

      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(@id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/ring_pools/" + URI.escape(ring_pool[ringpool_id_from_network].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))+ ".json"

      body = ring_pool.clone
      body.delete(:advertiser_id_from_network)
      body.delete(:advertiser_campaign_id_from_network)
      body.delete(:ringpool_id_from_network)

      @http.post_request(url, body)

    end

    def get_ring_pool(id)
      url = DOMAIN + "/api/2014-01-01/" + @network_id.to_s + "/advertisers/" + URI.escape(@advertiser_id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/advertiser_campaigns/" + URI.escape(@id_from_network.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) + "/ring_pools/" + URI.escape(id.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))+ ".json"
      @http.get_request(url)

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

    def create( affiliate_id_from_network, status = "Applied")
      url = DOMAIN + "/api/2015-05-01/" + @network_id + "/advertisers/" + URI::encode(@advertiser_id_from_network) + "/advertiser_campaigns/" + URI::encode(@advertiser_campaign_id_from_network) + "/affiliates/" + URI::encode(@affiliate_id_from_network.to_s) + "/affiliate_campaigns.json"
      body = {
          'status' => status,
          'affiliate_campaign_id_from_network' => affiliate_id_from_network.to_s
      }

      @http.post_request(url, body)
    end

    def pull_promo_numbers(quantity, media_type = "Online: Display", description = "Created on " + Time.now.strftime("%m/%d/%Y %H:%M"))

      numbers_needed = ( quantity.nil? ) ? 1 : quantity.to_i
      numbers_pulled = ""

      url = DOMAIN + "/api/2015-05-01/" + @network_id.to_s + "/advertisers/" + URI::encode(@advertiser_id_from_network.to_s) + "/advertiser_campaigns/" + URI::encode(@advertiser_campaign_id_from_network.to_s) + "/affiliates/" + URI::encode(@affiliate_id_from_network) + "/affiliate_campaigns/promo_numbers.json"

      body = {
          :description => description,
          :media_type  => media_type
      }

      while numbers_needed > 0
        puts "Attempting to pull a promo number"
        response = @http.post_request(url, body)

        if response.code.to_s == '200' || response.code.to_s == '201'
          details = JSON.parse(response.body)
          if numbers_needed == quantity.to_i
            numbers_pulled += details['promo_number']
          else
            numbers_pulled += "|" + details['promo_number']
          end
        else
          puts "\n\nmedia type: " + media_type.to_s + "\n\n"
          numbers_pulled += JSON.parse(response.body, :symbolize_names => true)[:errors].to_s
        end

        numbers_needed -= 1
      end

      return numbers_pulled
    end

  end

end
