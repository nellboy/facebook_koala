module Facebook

  def get_exchange_token(access_token)
    exchange_token = nil
    begin
      url = "https://graph.facebook.com/oauth/access_token?"+
      "grant_type=fb_exchange_token&"+
      "client_id=#{FACEBOOK_APP_ID}&"+
      "client_secret=#{FACEBOOK_APP_SECRET}&"+
      "fb_exchange_token=#{access_token}" 
      uri = URI.parse(URI.encode(url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      exchange_token = http.request(request).body.sub(/access_token=/, '').sub(/&expires=\d{4}/, '').strip
    rescue Exception => e
      logger.error(e)
    end
    exchange_token
  end

  def get_events(token, page_id)
    events = []
    if page_id
      user_graph = Koala::Facebook::API.new(token)
      user_graph.get_connections(page_id, 'events').reverse.each {|e|
        event = user_graph.get_object(e["id"])
        if event["venue"]
          venue = user_graph.get_object(event["venue"]["id"])
          event["city"] = venue["location"]["city"]
          event["country"] = venue["location"]["country"]
          event["address"] = venue["location"]["street"]
          event["venue"] = venue["name"]
        end
        event["date"] = parse_facebook_time(event["start_time"])
        event["details"] = event["name"]
        events << event
      }
    end
    events
  end

  def get_pages(token)
    pages = []
    user_graph = Koala::Facebook::API.new(token)
    user_graph.get_connections('me', 'accounts').reverse.each {|p|
      pages << {:name => p["name"], :id => p["id"]}
    }
    pages
  end

  def parse_facebook_time(time)
    Time.at(DateTime.parse(time).to_i)#.strftime('%Y-%m-%d %H:%M')
  end

  def parse_facebook_url url
    uri = URI.parse(URI.encode(url))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    JSON.parse(http.request(request).body)
  end

end