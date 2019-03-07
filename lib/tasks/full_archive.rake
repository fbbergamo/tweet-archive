namespace :tweet_archive do
  desc "Load full archive from politician target"
  task :full_archive => :environment do
    client = TwitterClient.instance.client
    search = client.premium_search("from:#{ENV["POLITICIAN_TWITTER"]}", {}, product: 'fullarchive')

    search.each do |tweet|
      Tweet.persist(tweet)
    end
  end
end
