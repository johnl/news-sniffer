module NewsArticlesHelper
  def revision_url(id, va, vb)
   "#{request.env["HTTP_HOST"]}/articles/#{id}/diff/#{va}/#{vb}"
  end
end
