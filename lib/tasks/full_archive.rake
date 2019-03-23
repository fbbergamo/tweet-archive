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
    tweets = []
    Tweet.find_each do |t|
      tweets << t.as_json.to_json
    end

    File.open('tmp/dump.gz', 'w') do |f|
      f.binmode
      gz = Zlib::GzipWriter.new(f)
      gz.write(tweets.join("\n").force_encoding(Encoding::UTF_8))
      gz.close
    end

    s3 = Aws::S3::Resource.new(region: ENV.fetch("AWS_S3_REGION", 'us-west-1'))

    obj = s3.bucket(ENV["S3_BUCKET_PATH"]).object(ENV["DUMP_FILE_NAME"])
    obj.upload_file("tmp/dump.gz", acl: "public-read")
  end
end
