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
class Vote < ActiveRecord::Base

  validates_presence_of :thing
  validates_uniqueness_of :thing_id, :scope => [:thing_type, :sessionid], :message => 'already voted'
  
  belongs_to :thing, :polymorphic => true, :counter_cache => :votes

  def self.vote!(thing, sessionid = rand(99999999))
    Vote.create!(:thing => thing, :sessionid => sessionid)
  end

end
