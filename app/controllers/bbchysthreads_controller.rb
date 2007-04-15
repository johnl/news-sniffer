class BbchysthreadsController < ApplicationController

  layout 'newsniffer'
  session :off
  caches_action :mostcensored, :all, :show

  def all
    @title = "Watch Your Mouth - latest threads"
    @threads_pages, @threads = 
      paginate :hys_threads, :order => 'created_at desc'
    render :action => 'list'
  end
  
  def latest
    @threads_pages, @threads = 
      paginate :hys_threads, :order => 'created_at desc'
    render :action => 'list'
  end
  
  def mostcensored
    @title = "Watch Your Mouth - most censored threads"  
    sql = "select hys_threads.*,count(hys_comments.id) as ccount from
      hys_threads left outer join hys_comments on hys_threads.id =
      hys_comments.hys_thread_id and hys_comments.censored = #{CENSORED} group by
      hys_threads.id order by ccount desc "

    @threads_pages = Paginator.new self, HysThread.count , 10, params['page']
    @threads = HysThread.find_by_sql(sql +
      "limit #{@threads_pages.current.offset},#{@threads_pages.items_per_page}" )
    render :action => 'list'
  end

  def show
    @thread = HysThread.find_by_bbcid(params[:id])
    @title = "Watch Your Mouth - '#{@thread.title}'"
    @comments = @thread.censored.find(:all, :order => "hys_comments.updated_at", :include => :hys_thread)
  end

end
