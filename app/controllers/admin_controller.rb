#    News Sniffer
#    Copyright (C) 2007-2008 John Leach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
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

