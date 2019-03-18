class HomeController < ApplicationController

  def index
    @sums_per_month = Tweet.sums_per_month
    @hours_ranking = Tweet.hours_ranking
    @entities_ranking = Tweet.entities_ranking
    @entities_person_ranking = Tweet.entities_ranking("PERSON")
    @entities_place_ranking = Tweet.entities_ranking("LOCATION")
    @entities_organization_ranking = Tweet.entities_ranking("ORGANIZATION")
    @entities_event_ranking = Tweet.entities_ranking("EVENT")

    @day_of_week_ranking = Tweet.day_of_week_ranking.transform_keys{|x| Date::DAYNAMES[x.to_i] }
    @reply_ranking = Tweet.reply_ranking
    @place_ranking = Tweet.place_ranking
    @source_ranking = Tweet.source_ranking
    @hashtags = Tweet.hashtags_ranking
    @mentions = Tweet.mentions_ranking
    @tweets_per_day = Tweet.tweets_per_day
    @tweets_per_month = Tweet.tweets_per_month
    @words = Tweet.words_ranking("ANY")
    @words_adj = Tweet.words_ranking("ADJ")
    @words_verb = Tweet.words_ranking("VERB")
    @reteweet_ranking = Tweet.reteweet_ranking
    @sentimental_ranking = Tweet.sentimental_ranking

    @sentimental_per_month = Tweet.sentimental_per_month.group_by{ |x| x["month"] }
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

    @media_per_month = Tweet.media_per_month
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
