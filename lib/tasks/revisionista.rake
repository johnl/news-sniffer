require 'stacked_logger'

def setup_logger
  logger = ActiveRecord::Base.logger = StackedLogger.new(ActiveRecord::Base.logger, STDOUT)
  logger.level = Logger::INFO
  logger
end

namespace "revisionista" do
  namespace :articles do
    desc "Hit the RSS feeds looking for new articles"
    task :update => :environment do
      logger = setup_logger
      logger.info "revisionista:articles:update"
      NewsArticleFeed.due_check.each do |feed|
        logger.info("NewsArticleFeed #{feed.id}")
        feed.create_news_articles
        feed.update_next_check_after!
      end
    end
  end

  namespace "versions" do
    desc "Check articles for new versions"
    task :update => :environment do
      logger = setup_logger
      logger.info "revisionista:versions:update"
      # Can't use find_in_batches here due to ordering and the with_scope bug
      NewsArticle.due_check.all(:limit => 1000).each do |article|
        begin
          article.update_from_source
        rescue StandardError => e
          logger.error "NewsArticle #{article.id} " + e.to_s
        end
      end
    end
  end

end
