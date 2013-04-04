# -*- coding: utf-8 -*-
require './TwitterBot.rb' # TwitterBot.rbの読み込み
require 'yaml'
require 'json'

#---------- MyTwitterBot ----------                                                                         
class MyTwitterBot < TwitterBot

  def initialize
    super
    self.get_bot_id
  end

  # 機能を追加
  def tweet( message )
    message << " tweet by bot."
    super
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
      if self.is_reply(post) then
        if self.search_tweet("｣と言って", post) then
          head = post["message"].index("｢") + 1
          tail = post["message"].rindex("｣") - 1
          self.tweet( post["message"].slice(head..tail))
        end

      end

    end

  end

  #--------- 誕生日の人がいれば@付きつぶやきを飛ばす ---------
  def notice_birth
    birthday_data = YAML.load_file('./birthday.yml')

    today = Time.now

    birthday_data.each do |prof|
      if prof["month"] == today.month then
        if prof["day"] == today.day then
          str = "今日は" 
          str << prof["name"] 
          str << " @" 
          str << prof["ID"] 
          str << " さんの誕生日です！みんなでお祝いしましょう！" 
          self.tweet( str )
        end

      end
      
    end

  end

  

end

#MyTwitterBotの生成
print "Start MyTwitterBot.\n"
mbot = MyTwitterBot.new()
#mbot.answer_say
#mbot.notice_birth
print "End MyTwitterBot.\n"

