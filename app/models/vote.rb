class Vote < ActiveRecord::Base

  before_destroy :dec_class_votes

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
