namespace "newssniffer" do
  namespace :articles do
    desc "Hit the RSS feeds looking for new articles"
    task :update => :environment do
      NewsArticleFeed.due_check.each do |feed|
        feed.create_news_articles
        feed.update_next_check_after!
      end
    end
  end

  namespace "versions" do
    desc "Check articles for new versions"
    task :update => :environment do
      sources = {}
      NewsArticleFeed.all.select(:source).group(:source).each do |feed|
        sources[feed.source] = NewsArticle.due_check.limit(200).where(:source => feed.source)
      end
      updater_threads = []
      sources.each do |source, articles|
        updater_threads << Thread.new do
          Rails.logger.info "task=versions:update source=%s articles_due=%s" % [source, articles.size]
          articles.each do |article|
            begin
              article.update_from_source
            rescue StandardError => e
              Rails.logger.error "task=versions:update source=%s article_id=%s error='%s'" % [source, article.id, e.to_s]
            end
          end
        end
        Rails.logger.info "task=versions:update source=#{source} status=completed"
      end
      updater_threads.each { |t| t.join }
    end
  end

end

namespace :xapian do
  desc "Reindex the NewsArticleVersion Xapian database"
  task :update => :environment do
    batch_size = (ENV["BATCH_SIZE"] || 1000).to_i
    max_batches = (ENV["MAX_BATCHES"] || 20).to_i
    Rails.logger.info "task=xapian:update batch_size=#{batch_size} max_batches=#{max_batches}"
    NewsArticleVersion.xapian_update(batch_size: batch_size,
                                     max_batches: max_batches)
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

namespace "assets" do
  task undigest: :environment do
    assets = Dir.glob(File.join(Rails.root, 'public/assets/**/*'))
    regex = /(-{1}[a-z0-9]{32}*\.{1}){1}/
    assets.each do |file|
      next if File.directory?(file) || file !~ regex

      source = file.split('/')
      source.push(source.pop.gsub(regex, '.'))

      non_digested = File.join(source)
      FileUtils.cp(file, non_digested)
    end
  end
end
