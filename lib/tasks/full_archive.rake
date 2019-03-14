namespace :tweet_archive do
  desc "Load full archive from politician target"
  task :full_archive => :environment do
    client = TwitterClient.instance.client
    search = client.premium_search("from:#{ENV["POLITICIAN_TWITTER"]}", {fromDate: '200712220000', maxResults: 500}, product: 'fullarchive')

    search.each do |tweet|
      Tweet.persist(tweet)
    end
  end

  desc "Load bk"
  task :load_bk => :environment do
    jsons = File.read("db/jairbolsonaro.json")
    j = jsons.split("\n").map{ |x| Tweet.persist(  Twitter::Tweet.new(JSON.parse(x).symbolize_keys)) }
  end

  desc "export to s3 last version"
  task :s3_export => :environment do
    # TODO:
  end
end
