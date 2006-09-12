class Variable < ActiveRecord::Base
  def self.get(key)
    v = self.find_by_key(key)
    return v.value if v
    return nil
  end
  
  def self.geti(key)
    v = self.get(key)
    return v.to_s if v
    return 0
  end
  
  def self.gets(key)
    v = self.get(key)
    return v if v
    return ""
  end

  def self.put(key,value)
    v = self.find_by_key(key)
    unless v
      v = self.new
      v.key = key
    end
    v.value = value
    v.save
  end
    
    
end
