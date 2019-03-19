class Tweet < ApplicationRecord
  scope :hashtags_ranking, -> (only_author = true) {
    select("lower(jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text') as hashtags")
    .where("raw #> '{entities,hashtags}' <> '[]'")
    .where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("lower(jsonb_array_elements(raw #> '{entities,hashtags}')  ->> 'text')").order("count(*) DESC").limit(20).size.to_a
  }

  scope :mentions_ranking, -> (only_author = true) {
    select("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name' as user_mentions")
    .where("raw #> '{entities,user_mentions}' <> '[]'")
    .where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :reply_ranking, -> (only_author = true) {
    select("raw #> '{in_reply_to_screen_name}' as reply_user")
    .where("raw ->> 'in_reply_to_screen_name' != ''")
    .where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("raw #> '{in_reply_to_screen_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :place_ranking, -> (only_author = true) {
    select("raw #> '{place,full_name}' as place")
    .where("raw #> '{place,full_name}' IS NOT NULL")
    .where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("raw #> '{place,full_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :source_ranking, -> (only_author = true) {
    select("raw #> '{source}' as source")
    .where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("raw #> '{source}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :reteweet_ranking, -> {
    select("raw #> '{retweeted_status,user,screen_name}' as user_mentions")
    .where("raw ->> 'retweeted_status' IS NOT NULL")
    .group("raw #> '{retweeted_status,user,screen_name}'").order("count(id) DESC").limit(20).size.to_a
  }

  scope :hours_ranking, -> (only_author = true) {
     where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("extract(hour from to_timestamp((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') AT TIME ZONE 'BRT')").count.sort
  }

  scope :day_of_week_ranking, -> (only_author = true) {
    where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("extract(dow from to_timestamp((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') AT TIME ZONE 'BRT')").count.sort.to_h
  }

  scope :sums_per_month, -> (only_author = true)  {
    ActiveRecord::Base.connection
      .execute(
        " SELECT date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,
          sum(CAST(  #{only_author ?  "raw ->> 'retweet_count'" : "raw #>> '{retweeted_status,retweet_count}'"} AS INTEGER)) as retweet_count,
          sum(CAST(  #{only_author ?  "raw ->> 'reply_count'" : "raw #>> '{retweeted_status,reply_count}'"} AS INTEGER)) as reply_count,
          sum(CAST(  #{only_author ?  "raw ->> 'favorite_count'" : "raw #>> '{retweeted_status,favorite_count}'"} AS INTEGER)) as favorite_count
           FROM tweets
           WHERE raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL
           GROUP BY date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY'))").to_a
  }


  scope :media_per_month, -> (only_author = true)  {
    ActiveRecord::Base.connection
      .execute(
        " SELECT COUNT(*) AS count, date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,
          jsonb_array_elements(raw #> '{extended_entities,media}')  ->> 'type' AS type
           FROM tweets
           WHERE raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL
           GROUP BY date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')),
           jsonb_array_elements(raw #> '{extended_entities,media}')  ->> 'type'").to_a
  }


  scope :tweets_per_day, -> (only_author = true)  {
     where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')").count
  }

  scope :tweets_per_month, -> (only_author = true)  {
     where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY'))").count
  }

  scope :words_ranking, -> (word_klass, only_author = true) {
    ActiveRecord::Base.connection
      .execute(
        "SELECT text, count(*) FROM (SELECT  jsonb_array_elements(detect_syntax) #>> '{part_of_speech,tag}' AS tag,
        lower(jsonb_array_elements(detect_syntax) ->> 'text') as text FROM tweets  WHERE raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL ) as tags WHERE
        text NOT IN (#{StopWords::LIST.map{|x| "'#{x}'" }.join(',')}) #{word_klass != 'ANY' ?  "AND tag = '#{word_klass}'" : "AND tag != 'PUNCT'"}
        GROUP BY text ORDER by count(*) DESC LIMIT 50"
      ).to_a
  }

  scope :entities_ranking, -> (type = 'ANY', only_author = true) {
    ActiveRecord::Base.connection
      .execute(
        "SELECT text, count(*) FROM (SELECT  jsonb_array_elements(detect_entities) #>> '{type}' AS type,
        lower(jsonb_array_elements(detect_entities) ->> 'text') as text FROM tweets WHERE raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL ) as tags
       #{type != 'ANY' ?  "WHERE type = '#{type}'" : ""}
        GROUP BY text ORDER by count(*) DESC LIMIT 50"
      ).to_a
  }

  scope :sentimental_per_day,  ->  (only_author = true)  {
    ActiveRecord::Base.connection
      .execute(
        "SELECT to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY') as day,  detect_sentiment ->> 'sentiment' as sentiment, count(*) FROM tweets
        raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL
        GROUP BY day, sentiment ORDER by day"
      ).to_a
  }

  scope :sentimental_per_month,  ->  (only_author = true)  {
    ActiveRecord::Base.connection
      .execute(
        "SELECT date_trunc('month', to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY')) as month,  detect_sentiment ->> 'sentiment' as sentiment, count(*) FROM tweets
         WHERE raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL
        GROUP BY month, sentiment ORDER by month"
      ).to_a
  }

  scope :sentimental_ranking, -> (only_author = true)  {
    where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .group("detect_sentiment -> 'sentiment'").count
  }

  scope :sentimental_tweets_ranking, -> (only_author = true)  {
    where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .where("detect_sentiment #> '{sentiment_score,negative}' IS NOT NULL")
    .order(" detect_sentiment #> '{sentiment_score,negative}' DESC")
  }

  scope :domains_ranking, -> (only_author = true)  {
    where("raw ->> 'retweeted_status' IS #{only_author ?  '' : 'NOT'} NULL")
    .where("raw #> '{entities,urls}' <> '[]'")
    .map{|t| t.raw["entities"]["urls"].map{|u| u["expanded_url"] } }
    .flatten.compact
    .map{|x| get_host_without_www(x)}.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by {|k, v| -v}
  }

  def self.get_host_without_www(url)
    url = "http://#{url}" unless url.start_with?('http')
    uri = URI.parse(url)
    host = uri.host.downcase
    host.start_with?('www.') ? host[4..-1] : host
  end

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
