class Http

  def initialize(params)
    @verb    = params[:verb]
    @url     = params[:url]
    @body    = params[:body]
    @api_key = params[:api_key]
  end

  attr_reader :verb, :url, :body, :api_key

  def get(url, api_token)
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

  def post(url, body, api_token)
    uri = URI(url)
    params = { :oauth_token =>  api_token}
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new(uri.to_s)
      request["Content-Type"] = 'application/json'
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

end