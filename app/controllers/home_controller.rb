class HomeController < ApplicationController
  caches_action :index

  def index
    remove_retweets = params[:retweets].present? ? false : true
    @sums_per_month = Tweet.sums_per_month(remove_retweets)

    @hours_ranking = Tweet.hours_ranking(remove_retweets)
    @reteweet_ranking = Tweet.reteweet_ranking
    @entities_ranking = Tweet.entities_ranking("ANY", remove_retweets)
    @entities_person_ranking = Tweet.entities_ranking("PERSON",remove_retweets)
    @entities_place_ranking = Tweet.entities_ranking("LOCATION",remove_retweets)
    @entities_organization_ranking = Tweet.entities_ranking("ORGANIZATION",remove_retweets)
    @entities_event_ranking = Tweet.entities_ranking("EVENT",remove_retweets)
    @domains_ranking = Tweet.domains_ranking(remove_retweets)[0..19]
    @day_of_week_ranking = Tweet.day_of_week_ranking(remove_retweets).transform_keys{|x| Date::DAYNAMES[x.to_i] }
    @reply_ranking = Tweet.reply_ranking(remove_retweets)
    @place_ranking = Tweet.place_ranking(remove_retweets)
    @source_ranking = Tweet.source_ranking(remove_retweets)
    @hashtags = Tweet.hashtags_ranking(remove_retweets)
    @mentions = Tweet.mentions_ranking(remove_retweets)
    @tweets_per_day = Tweet.tweets_per_day(remove_retweets)
    @tweets_per_month = Tweet.tweets_per_month(remove_retweets)
    @words = Tweet.words_ranking("ANY", remove_retweets)
    @words_adj = Tweet.words_ranking("ADJ", remove_retweets)
    @words_verb = Tweet.words_ranking("VERB", remove_retweets)
    @words_adv = Tweet.words_ranking("ADV", remove_retweets)
    @words_noun = Tweet.words_ranking("NOUN", remove_retweets)

    @sentimental_ranking = Tweet.sentimental_ranking(remove_retweets)

    @sentimental_per_month = Tweet.sentimental_per_month(remove_retweets).group_by{ |x| x["month"] }
          .map{ |x|
            next if x[0].nil?
          count_positive = x[1].select{|x| x['sentiment'] == 'POSITIVE' }&.first&.dig("count") || 0
          count_negative = x[1].select{|x| x['sentiment'] == 'NEGATIVE' }&.first&.dig("count") || 0
          count_neutral = x[1].select{|x| x['sentiment'] == 'NEUTRAL' }&.first&.dig("count") || 0
          {
            date: Date.parse(x[0]).to_s,
            count_postive: count_positive,
            count_negative: count_negative,
            count_neutral: count_neutral,
            score: ((-1*count_negative + (count_positive + count_neutral)).to_f / ((count_negative + count_positive + count_neutral).zero? ? 1 : count_negative + count_positive  + count_neutral).to_f)
          }
        }.compact

    @media_per_month = Tweet.media_per_month(remove_retweets)
        .group_by{ |x| x["month"] }
        .map{ |x|
        count_video = x[1].select{|x| x['type'] == 'video' }&.first&.dig("count") || 0
        count_photo = x[1].select{|x| x['type'] == 'photo' }&.first&.dig("count") || 0
        {
          date: Date.parse(x[0]).to_s,
          count_video: count_video,
          count_photo: count_photo
        }
      }
  end
end
