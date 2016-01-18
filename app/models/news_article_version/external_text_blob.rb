# Methods to transparently handle storing the text field in a separate model.
# This was originally done for MySQL performance reasons.
module NewsArticleVersion::ExternalTextBlob
  def self.included(base)
    base.send :has_one, :news_article_version_text, dependent: :delete
    base.send :before_validation, :setup_text
    base.send :after_save, :update_text
  end

  def text
    @text ||= news_article_version_text.to_s
  end

  def text=(new_text)
    @text_changed = true if @text != new_text
    @text = new_text
  end

  private

  def setup_text
    build_news_article_version_text unless news_article_version_text
    true
  end

  def update_text
    if @text_changed
      news_article_version_text.update_attributes(text: @text)
    end
    true
  end
end
