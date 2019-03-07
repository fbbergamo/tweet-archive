class RankingController < ApplicationController
 def index
   @list = []
   type = params[:type]
   if type == 'hashtags'
     @list = Tweet.select("jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text'as hashtags")
     .where("raw #> '{entities,hashtags}' <> '[]' ")
     .group("jsonb_array_elements(raw #> '{entities,hashtags}')  -> 'text'").order("count(*) DESC").limit(20).size
   elsif type == 'user_mentions'
     @list = Tweet.select("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name' as user_mentions")
     .where("raw #> '{entities,user_mentions}' <> '[]' ")
     .group("jsonb_array_elements(raw #> '{entities,user_mentions}')  -> 'screen_name'").order("count(*) DESC").limit(20).size
   end

   render json: @list
 end
end
