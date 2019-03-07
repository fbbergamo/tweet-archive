class RankingController < ApplicationController
 def index
   @list = []
   type = params[:type]
   if type == 'hashtags'
     @list = Tweet.hashtags_ranking
   elsif type == 'user_mentions'
     @list = Tweet.mentions_ranking
   elsif type = 'calendar_heatmap'
     @list = Tweet.calendar_heatmap
   end

   render json: @list
 end
end
