class AdminController < ApplicationController

  layout 'newsniffer'

  def login
    @admin_bar = true
    return unless request.post?
    if params[:pswd] == ENV['ADMIN_PASSWORD']
      session[:admin] = true
      flash[:notice] = 'Logged in successfully'
      redirect_to :controller => 'bbchyscomments', :action => 'list'
    else
      flash[:error] = 'Wrong password, you dolt'
    end
  end

  def logout
    @admin_bar = true
    session[:admin] = nil
    flash[:notice] = 'You have been logged out'
    redirect_to :action => 'login'
  end

end

