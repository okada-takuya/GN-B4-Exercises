# -*- coding: utf-8 -*-

require './TwitterBot.rb' # TwitterBot.rbの読み込み
require './GCal.rb'       # GCal.rbの読み込み
require 'yaml'
require 'json'
require 'open-uri'
require 'rubygems'
require 'google/api_client'


#---------- MyTwitterBot ----------                                                                         
class MyTwitterBot < TwitterBot
  
  def initialize
    super
    self.get_bot_id
    @gc = GCal.new()
    @NOW = Time.now 
  end

  #--------- 140字以上の文字列か判定 ---------
  def is_over_140(msg)
    if msg.length > 140
      puts "ERROR: Message is longer than 140 characters."
      puts "       Stop message =>" + msg
      return true
    end
    return false
  end

  #--------- tweet投稿失敗か判定 ---------
  def is_tweeted( res, msg )
    /HTTP(.+):/ =~ res.to_s
    if (/Forbidden/ =~ $1) != nil
      puts "ERROR: Can't tweet."
      puts "       Blocked message =>" + msg
    end
  end
  
  #--------- 以前と同じ内容にならないよう時間を付け加える ---------
  def tweet( msg )
    sleep(2)
    msg << " tweet by bot." + @NOW.to_s
    if is_over_140(msg) == false
      res = super
      is_tweeted( res, msg )
    end
  end
  
  #--------- BotのIDを取得する ---------
  def get_bot_id
    response = @access_token.get(
                                 '/account/verify_credentials.json'
                                 )
    
    mystatus = JSON.parse( response.body )
    @bot_id = mystatus["screen_name"]
    
  end
  
  #--------- Botへのリプライか真偽を取得  ---------
  def is_reply( tw )
    return self.search_tweet( @bot_id, tw )
  end
  
  #--------- tweetからstrの存在を検索 ---------
  def search_tweet( str, post )
    return post["message"].index(str) != nil
  end
  
  #--------- 言ってに返信  ---------
  def answer_say
    tweets = self.get_tweet
    
    tweets.each do |post|
      if self.is_reply(post) 
        if (/｢(.+)｣と言って/ =~ post["message"]) != nil  
          self.tweet( $1 )
        end
        
      end
      
    end
    
  end
  
  #--------- 誕生日の人がいれば@付きつぶやきを飛ばす ---------
  def notice_birth
    birthday_data = YAML.load_file('./birthday.yml')
    
    today = Time.now
 
    birthday_data.each do |prof|
      if prof["month"] == today.month 
        if prof["day"] == today.day
          str = "今日は" + prof["name"] + " @" + prof["ID"] \
          +  " さんの誕生日です！みんなでお祝いしましょう！" 
          self.tweet( str )
        end
        
      end
      
    end
    
  end
  
  #--------- 起動日が雨だと傘持ち込みtweet  ---------
  def notice_weather
    open("http://weather.livedoor.com/forecast/webservice/json/v1?city=330010"){|io|
      weathers = JSON.parse(io.read)
      tweather = weathers['forecasts'].shift['telop']
      if (/雨/ =~ tweather) != nil 
        mes = "みなさん今日のお天気は" + tweather + "です! 傘を忘れずに持ってきましょう!"
        self.tweet(mes)
      end
    }
  end

  #--------- 打合せ3日以内ならツイート ---------
  def notice_meeting
    @gc = GCal.new()
    meetings = @gc.get_meeting
    meetings.each do |meeting|
      left = @gc.how_many_days_left( meeting['date_time'] )
      if left['days'] <= 3
        msg = "GNグループのみなさん， " + meeting['summary'] + "があと" + (left["days"]).to_s + "日と" + (left["hours"]).to_s + "時間に迫っています．" 
        self.tweet(msg)
      end
    end
  end

  #--------- 出張をお知らせ  ---------
  def notice_business_trip
    b_trips = @gc.get_business_trip
    b_trips.each do |b_trip|
      if b_trip['date_s'] <= @NOW && @NOW <= b_trip['date_e']
        msg = "今日は" + b_trip['summary'] + "です． 今回の出張は" + b_trip['date_e'].strftime("%m月%d日") + "までです．"
        self.tweet( msg )
      end

    end
  end
  
end

#MyTwitterBotの生成
print "Start MyTwitterBot.\n"
mbot = MyTwitterBot.new()
mbot.answer_say
mbot.notice_birth
mbot.notice_weather
mbot.connect_gcalendar
mbot.get_schedule
mbot.notice_meeting
mbot.notice_business_trip
print "End MyTwitterBot.\n"

