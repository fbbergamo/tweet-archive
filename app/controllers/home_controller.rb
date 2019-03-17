class HomeController < ApplicationController
  def index
    @hashtags = Tweet.hashtags_ranking
    @mentions = Tweet.mentions_ranking
    @tweets_per_day = Tweet.tweets_per_day
    @words = Tweet.words_ranking("ANY")
    @words_adj = Tweet.words_ranking("ADJ")
    @words_verb = Tweet.words_ranking("VERB")
    @reteweet_ranking = Tweet.reteweet_ranking
    @sentimental_ranking = Tweet.sentimental_ranking
    @sentimental_per_day = Tweet.sentimental_per_day
    @sentimental_per_day = @sentimental_per_day
      .group_by{ |x| x["day"] }
      .map{ |x|
      count_positive = x[1].select{|x| x['sentiment'] == 'POSITIVE' }&.first&.dig("count") || 0
      count_negative = x[1].select{|x| x['sentiment'] == 'NEGATIVE' }&.first&.dig("count") || 0
      count_neutral = x[1].select{|x| x['sentiment'] == 'NEUTRAL' }&.first&.dig("count") || 0
      {
        date: x[0],
        count_postive: count_positive,
        count_negative: count_negative,
        count_neutral: count_neutral,
        score: (-1*count_negative + count_positive) / ((count_negative + count_positive).zero? ? 1 : count_negative + count_positive)
      }
    }

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

  end
end
