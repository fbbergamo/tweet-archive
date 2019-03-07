class HomeController < ApplicationController
  def index
    @hashtags = Tweet.hashtags_ranking
    @mentions = Tweet.mentions_ranking
    @calendar_heatmap = Tweet.calendar_heatmap
  end
end
