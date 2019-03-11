class AddDetectNlpFields < ActiveRecord::Migration[5.2]
  def change
    add_column :tweets,  :detect_syntax, :jsonb
    add_column  :tweets, :detect_sentiment, :jsonb
    add_column  :tweets, :detect_entities, :jsonb
  end
end
