namespace :tweet_archive do
  desc "Load detect syntax using AWS comprehend"
  task :detect_syntax => :environment do
    client = Aws::Comprehend::Client.new
    Tweet.where("detect_syntax IS NULL").find_each do |t|
      result = client.detect_syntax(text: t.text, language_code: "pt")
      next if result.blank?

      json = result.syntax_tokens.as_json
      t.update_column(:detect_syntax, json)
    end
  end

  desc "Load detect sentiment using AWS comprehend"
  task :detect_sentiment => :environment do
    client = Aws::Comprehend::Client.new
    Tweet.where("detect_sentiment IS NULL").find_each do |t|
      result = client.detect_sentiment(text: t.text, language_code: "pt")
      next if result.blank?

      json = {
        sentiment: result.sentiment.to_s,
        sentiment_score: result.sentiment_score.as_json
      }

      t.update_column(:detect_sentiment, json)
    end
  end

  desc "Load detect entities using AWS comprehend"
  task :detect_entities => :environment do
    client = Aws::Comprehend::Client.new
    Tweet.where("detect_entities IS NULL").find_each do |t|
      result = client.detect_entities(text: t.text, language_code: "pt")
      next if result.blank?

      json = result.entities.as_json
      t.update_column(:detect_entities, json)
    end
  end
end
