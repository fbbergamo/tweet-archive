class HomeController < ApplicationController
  def index
    @hashtags = Tweet.hashtags_ranking
    @mentions = Tweet.mentions_ranking
    @calendar_heatmap = Tweet.calendar_heatmap
    @words = Tweet.words_ranking("ANY")
    @words_adj = Tweet.words_ranking("ADJ")
    @words_verb = Tweet.words_ranking("VERB")
    @reteweet_ranking = Tweet.reteweet_ranking
    @sentimental_ranking = Tweet.sentimental_ranking
    @sentimental_per_day = Tweet.sentimental_per_day
    @sentimental_per_day = @sentimental_per_day
      .group_by{ |x| x["day"] }
      .map{ |x| {
        date: x[0],
        count_postive: x[1].select{|x| x['sentiment'] == 'POSITIVE' }&.first&.dig("count") || 0,
        count_negative: x[1].select{|x| x['sentiment'] == 'NEGATIVE' }&.first&.dig("count") || 0,
        count_neutral: x[1].select{|x| x['sentiment'] == 'NEUTRAL' }&.first&.dig("count") || 0
      }
    }

  end
end
