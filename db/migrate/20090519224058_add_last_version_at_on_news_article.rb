class AddLastVersionAtOnNewsArticle < ActiveRecord::Migration
  def self.up
    add_column :news_articles, :last_version_at, :datetime
    NewsArticle.find_each do |na|
      latest_version = na.versions.first(:order => 'id desc')
      if latest_version.nil?
        na.update_attributes(:next_check_after => Time.now, :check_period => 0)
      else
        # schedule the next check to be now plus the period between
        # now and the latest version. So, 
        check_period = Time.now - latest_version.created_at
        na.update_attributes(:last_version_at => latest_version.created_at,
                             :title => latest_version.title,
                             :check_period => check_period,
                             :next_check_after => Time.now - check_period)
      end
    end
  end

  def self.down
    remove_column :news_articles, :last_version_at
  end
end
