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

  before_destroy :dec_class_votes

  def voted_object
    eval(read_attribute('class')).find(self.relation_id)
  end

  def self.vote(ob, sessionid = rand(99999999))
    return false unless ob.is_a? ActiveRecord::Base
    return false if Vote.find(:first, 
      :conditions => ['class = ? and sessionid = ? and relation_id = ?', ob.class.class_name, sessionid, ob.id])
    ob.class.increment_counter('votes', ob.id) if ob.class.column_names.include? "votes"
    return Vote.create( { :class => ob.class.class_name, :sessionid => sessionid, :relation_id => ob.id } )
  end

  private

  def dec_class_votes
    obclass = eval(read_attribute('class'))
    obclass.decrement_counter('votes', relation_id) if obclass.column_names.include? "votes"
  end

end
