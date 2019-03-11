class Tweet < ApplicationRecord
  scope :hashtags_ranking, -> {
    select("jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text'as hashtags")
    .where("raw #> '{entities,hashtags}' <> '[]' ")
    .group("jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text'").order("count(*) DESC").limit(20).size.to_a
  }

  scope :mentions_ranking, -> {
    select("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name' as user_mentions")
    .where("raw #> '{entities,user_mentions}' <> '[]' ")
    .group("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name'").order("count(*) DESC").limit(20).size.to_a
  }

  scope :calendar_heatmap, -> {
    group("extract(epoch from to_date((raw ->> 'created_at'), 'Dy Mon DD HH24:MI:SS +0000 YYYY'))").count
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
