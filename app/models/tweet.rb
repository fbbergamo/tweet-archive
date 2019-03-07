class Tweet < ApplicationRecord

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
end
