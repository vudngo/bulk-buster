# ------------- #
# HTTP Requests #
# ------------- #

# def cls
#   puts `clear`
# end

class HttpRequest

  # Init
  attr_accessor :api_key

  def initialize(api_key)
    @api_key = api_key
  end

  # Get request
  def get_request(url)
    uri = URI(url)
    params = { :oauth_token => @api_key }
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      response = http.request request
      if response.code.to_s != '200' && response.code.to_s != '201'
        puts response.code.to_s + " : Get Request \n\n"
        puts url
      end

      return response
    end
  end

  # Post Request
  def post_request(url, body)
    uri = URI(url)
    params = { :oauth_token => @api_key }
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new uri.to_s
      request["Content-Type"] = 'application/json'
      request.body = body.to_json
      response = http.request request

      puts "Response: " + response.code.to_s

      puts "\n"

      if response.code.to_s != '200' && response.code.to_s != '201'
        puts ( url + "\n" + response.code.to_s + " : Skipping Campaign\n\n" )
      end

      return response
    end
  end

  # Put request
  def put_request(url, body)
    uri = URI(url)
    params = { :oauth_token => @api_key }
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Put.new uri.to_s
      request["Content-Type"] = 'application/json'
      request.body = body.to_json
      response = http.request request

      puts "Response: " + response.code.to_s

      puts ("\n")

      if response.code.to_s != '200' && response.code.to_s != '201'
        puts ( url + " - " + response.code.to_s + " - Skipping Campaign\n\n" )
        return false
      end

      return response

    end
  end

end # End of HttpRequest