require 'stacked_logger'

def setup_logger
  logger = ActiveRecord::Base.logger = StackedLogger.new(ActiveRecord::Base.logger, STDOUT)
  logger.level = Logger::INFO
  logger
end

namespace "newssniffer" do
  namespace :articles do
    desc "Hit the RSS feeds looking for new articles"
    task :update => :environment do
      logger = setup_logger
      logger.info "newssniffer:articles:update"
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
      logger.info "newssniffer:versions:update"
      sources = {}
      NewsArticleFeed.all.select(:source).group(:source).each do |feed|
        sources[feed.source] = NewsArticle.due_check.limit(200).where(:source => feed.source)
      end
      updater_threads = []
      sources.each do |source, articles|
        updater_threads << Thread.new do
          logger.info "newssniffer:versions:update starting thread for source #{source} with #{articles.size} articles"
          articles.each do |article|
            begin
              article.update_from_source
            rescue StandardError => e
              logger.error "NewsArticle #{article.source} #{article.id} " + e.to_s
            end
          end
        end
        logger.info "newssniffer:versions:update thread for source #{source} completed."
      end
      updater_threads.each { |t| t.join }
    end
  end

end

namespace :xapian do
  desc "Reindex the NewsArticleVersion Xapian database"
  task :update => :environment do
    logger = setup_logger
    logger.info "xapian:update"
    NewsArticleVersion.xapian_update
  end
end

# For backwards compatability with older News Sniffer deployments
namespace "revisionista" do
  namespace :articles do
    task :update => "newssniffer:articles:update" do
    end
  end
  namespace :versions do
    task :update => "newssniffer:versions:update" do
    end
  end
end
