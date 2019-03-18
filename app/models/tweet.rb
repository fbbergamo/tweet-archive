class Tweet < ApplicationRecord
  scope :hashtags_ranking, -> (remove_retweets = true) {
    select("lower(jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text') as hashtags")
    .where("raw #> '{entities,hashtags}' <> '[]'  #{remove_retweets ? "AND raw ->> 'retweeted_status' IS NULL" : ''}")
    .group("lower(jsonb_array_elements(raw #> '{entities,hashtags}')  ->> 'text')").order("count(*) DESC").limit(20).size.to_a
  }

  scope :mentions_ranking, -> (remove_retweets = true) {
    select("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name' as user_mentions")
    .where("raw #> '{entities,user_mentions}' <> '[]' #{remove_retweets ? "AND raw ->> 'retweeted_status' IS NULL" : ''} ")
    .group("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :reply_ranking, -> (remove_retweets = true) {
    select("raw #> '{in_reply_to_screen_name}' as reply_user")
    .where("raw ->> 'retweeted_status' IS NULL AND raw ->> 'in_reply_to_screen_name' != ''")
    .group("raw #> '{in_reply_to_screen_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :place_ranking, -> (remove_retweets = true) {
    select("raw #> '{place,full_name}' as place")
    .where("raw ->> 'retweeted_status' IS NULL AND raw #> '{place,full_name}' IS NOT NULL")
    .group("raw #> '{place,full_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :source_ranking, -> (remove_retweets = true) {
    select("raw #> '{source}' as source")
    .where("raw ->> 'retweeted_status' IS NULL")
    .group("raw #> '{source}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :reteweet_ranking, -> (remove_retweets = true) {
    select("raw #> '{retweeted_status,user,screen_name}' as user_mentions")
    .where("raw ->> 'retweeted_status' IS NOT NULL")
    .group("raw #> '{retweeted_status,user,screen_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :hours_ranking, -> (remove_retweets = true) {
     where("raw ->> 'retweeted_status' IS NOT NULL")
    .group("extract(hour from to_timestamp((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') AT TIME ZONE 'BRT')").count.sort
  }

  scope :day_of_week_ranking, -> (remove_retweets = true) {
     where("raw ->> 'retweeted_status' IS NOT NULL")
    .group("extract(dow from to_timestamp((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') AT TIME ZONE 'BRT')").count.sort.to_h
  }

  scope :sums_per_month, -> (remove_retweets = true)  {
    ActiveRecord::Base.connection
      .execute(
        " SELECT date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,
          sum(CAST(raw ->> 'retweet_count' AS INTEGER)) as retweet_count,
          sum(CAST(raw ->> 'reply_count' AS INTEGER)) as reply_count,
          sum(CAST(raw ->> 'favorite_count' AS INTEGER)) as favorite_count
           FROM tweets
           #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''}
           GROUP BY date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY'))").to_a
  }


  scope :media_per_month, -> (remove_retweets = true)  {
    ActiveRecord::Base.connection
      .execute(
        " SELECT COUNT(*) AS count, date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,
          jsonb_array_elements(raw #> '{extended_entities,media}')  ->> 'type' AS type
           FROM tweets
           #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''}
           GROUP BY date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')),
           jsonb_array_elements(raw #> '{extended_entities,media}')  ->> 'type'").to_a
  }


  scope :tweets_per_day, -> (remove_retweets = true)  {
     where("#{remove_retweets ? "raw ->> 'retweeted_status' IS NULL" : ''} ")
    .group("to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')").count
  }

  scope :tweets_per_month, -> (remove_retweets = true)  {
     where("#{remove_retweets ? "raw ->> 'retweeted_status' IS NULL" : ''} ")
    .group("date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY'))").count
  }

  scope :words_ranking, -> (word_klass, remove_retweets = true) {
    ActiveRecord::Base.connection
      .execute(
        "SELECT text, count(*) FROM (SELECT  jsonb_array_elements(detect_syntax) #>> '{part_of_speech,tag}' AS tag,
        lower(jsonb_array_elements(detect_syntax) ->> 'text') as text FROM tweets #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''} ) as tags WHERE
        text NOT IN (#{StopWords::LIST.map{|x| "'#{x}'" }.join(',')}) #{word_klass != 'ANY' ?  "AND tag = '#{word_klass}'" : "AND tag != 'PUNCT'"}
        GROUP BY text ORDER by count(*) DESC LIMIT 50"
      ).to_a
  }

  scope :entities_ranking, -> (type = 'ANY', remove_retweets = true) {
    ActiveRecord::Base.connection
      .execute(
        "SELECT text, count(*) FROM (SELECT  jsonb_array_elements(detect_entities) #>> '{type}' AS type,
        lower(jsonb_array_elements(detect_entities) ->> 'text') as text FROM tweets #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''} ) as tags
       #{type != 'ANY' ?  "WHERE type = '#{type}'" : ""}
        GROUP BY text ORDER by count(*) DESC LIMIT 50"
      ).to_a
  }

  scope :sentimental_per_day,  ->  (remove_retweets = true)  {
    ActiveRecord::Base.connection
      .execute(
        "SELECT to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') as day,  detect_sentiment ->> 'sentiment' as sentiment, count(*) FROM tweets
         #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''}
        GROUP BY day, sentiment ORDER by day"
      ).to_a
  }

  scope :sentimental_per_month,  ->  (remove_retweets = true)  {
    ActiveRecord::Base.connection
      .execute(
        "SELECT date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,  detect_sentiment ->> 'sentiment' as sentiment, count(*) FROM tweets
         #{remove_retweets ? "WHERE raw ->> 'retweeted_status' IS NULL " : ''}
        GROUP BY month, sentiment ORDER by month"
      ).to_a
  }

  scope :sentimental_ranking, -> (remove_retweets = true)  {
    where("#{remove_retweets ? "raw ->> 'retweeted_status' IS NULL" : ''} ")
    .group("detect_sentiment -> 'sentiment'").count
  }

  scope :sentimental_tweets_ranking, -> (remove_retweets = true)  {
    where("#{remove_retweets ? "raw ->> 'retweeted_status' IS NULL" : ''}")
    .where("detect_sentiment #> '{sentiment_score,negative}' IS NOT NULL")
    .order(" detect_sentiment #> '{sentiment_score,negative}' DESC")
  }

  def self.persist(tweet_api)
    begin
      tweet = self.find_or_create_by(tweet_id: tweet_api.id) do |t|
        t.raw = tweet_api.attrs
        t.checked_at = Time.zone.now
      end

      if !tweet.new_record?
        tweet.update_column(:checked_at, Time.zone.now)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def api_object
    @api_object ||= Twitter::Tweet.new(raw.symbolize_keys)
  end

  def text
    raw['retweeted_status'].present? ? check_extend_tweet(raw['retweeted_status']) : check_extend_tweet(raw)
  end

  private

  def check_extend_tweet(obj)
    obj['extended_tweet'].present? ? obj['extended_tweet']['full_text'] : obj['text']
  end
end
