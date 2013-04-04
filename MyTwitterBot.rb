# -*- coding: utf-8 -*-
require './TwitterBot.rb' # TwitterBot.rbの読み込み

#---------- MyTwitterBot ----------                                                                         
class MyTwitterBot < TwitterBot

  # 機能を追加
  def tweet( message )
    message << " tweet by bot."
    super
  end
  
  #--------- Okada_Tkyへのリプライを取得  ---------
  def is_reply( tw )
    return self.search_tweet("@Okada_Tky", tw)
  end
  
  #--------- tweetからstrの存在を検索 ---------
  def search_tweet( str, tw )
    return tw["message"].index(str) != nil
  end
  
  #--------- 言ってに返信  ---------
  def answer_say
    tweets = self.get_tweet
    
    tweets.each do |tw|
      if self.is_reply(tw) then
        if self.search_tweet("｣と言って", tw) then
          @head = tw["message"].index("｢") + 1
          @tail = tw["message"].rindex("｣") - 1
          self.tweet( tw["message"].slice(@head..@tail))
        end

      end

    end

  end

  

  

end

#MyTwitterBotの生成
print "Start MyTwitterBot.\n"
mbot = MyTwitterBot.new()
mbot.answer_say
print "End MyTwitterBot.\n"

