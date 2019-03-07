class Tweets < ActiveRecord::Migration[5.2]
  def change
    create_table :tweets do |t|
      t.column :raw, :jsonb
      t.column :tweet_id, :string
      t.column :checked_at, :datetime
      t.timestamp
    end

    add_index :tweets, :tweet_id, unique: true
  end
end
