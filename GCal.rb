# -*- coding: utf-8 -*-
require 'yaml'
require 'rubygems'
require 'google/api_client'


class GCal
  SEC_DAY = 86400
  def initialize
    #--------- グーグルカレンダーと接続 ---------
    oauth_yaml = YAML.load_file('.google-api.yaml')
    @client = Google::APIClient.new("application_name" => "MyTwitterBot")
    @client.authorization.client_id = oauth_yaml["client_id"]
    @client.authorization.client_secret = oauth_yaml["client_secret"]
    @client.authorization.scope = oauth_yaml["scope"]
    @client.authorization.refresh_token = oauth_yaml["refresh_token"]
    @client.authorization.access_token = oauth_yaml["access_token"]

    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end

    @service = @client.discovered_api('calendar', 'v3')
    
  end

  #--------- 終日でない打合せ予定を取得して配列を返す ---------
  def get_meeting

    mail_yaml = YAML.load_file('mailaddress.yml')
    mail = mail_yaml['mailaddress']

    page_token = nil
    result = result = @client.execute(:api_method => @service.events.list,
                                      :parameters => {'calendarId' => mail})
    
    while true
      events = result.data.items
      meetings = Array.new
      today =Time.now
      events.each do |e|
        if e.summary != nil && e.start.date_time != nil
          if today < e.start.date_time
            if (/打合せ/ =~ e.summary) != nil
              meetings.push("summary" => e.summary, "date_time" => e.start.date_time)
            end
          end
        end
      end
      if !(page_token = result.data.next_page_token)
        break
      end
      result = result = @client.execute(:api_method => @service.events.list,
                                        :parameters => {'calendarId' => mail, 'pageToken' => page_token})
    end
    
    return meetings
  
  end

  #--------- 与えられた日付まで残り何日かを判定 ---------
  def how_many_days_left( date_time ) 
    today = Time.now
    left = Array.new
    days_left = (date_time - today).divmod(24*60*60)
    hours_left = days_left[1].divmod(60*60)
    left = {"days" => days_left[0], "hours" => hours_left[0]}
    return left

  end


end
