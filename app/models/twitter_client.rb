class TwitterClient
  attr_accessor :client
  include Singleton

  def self.instance
    @@instance ||= new
  end

  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
      config.dev_environment     = ENV.fetch("TWITTER_ENVIROMENT", "development")
    end
  end
end
