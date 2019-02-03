class HealthController < ApplicationController
  def check
    NewsArticle.first
    render :status => 200, :text => "OK"
  end
end
