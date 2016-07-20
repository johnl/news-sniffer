module HTMLDiff
  require 'diff/lcs'
  require 'diff/lcs/callbacks'
  require 'diff/lcs/string'
        
  class WordDiff
    
    def transpose
      @words.transpose
    end
    
    def initialize
      @words = []
    end

    def match(event)
      @words << [" #{event.old_element}", " #{event.new_element} "]
    end

    def discard_a(event)
      @words << ["<del> #{event.old_element} </del>", ""]
    end

    def discard_b(event)
      @words << ["","<ins> #{event.new_element} </ins>"]
    end
    
    def change(event)
      @words << ["<del> #{event.old_element} </del>", "<ins> #{event.new_element} </ins>"]
    end
  end 
    
  class ParagraphDiff

    def to_html
      i = 0
      @rows.collect { |row| "<tr id='p#{i+=1}'>#{row.first}#{row.last}</tr>" }.join("\n")
    end

    def initialize
      @rows = []
    end

    def match(event)
      @rows << [event.old_element, event.new_element]
    end

    def discard_a(event)
      @rows << ["<td class='diff-row diff-row-first'></td><td><del>#{event.old_element}</del></td>", "<td class='diff-row diff-row-last'></td><td></td>"]
    end

    def discard_b(event)
      @rows << ["<td class='diff-row diff-row-first'></td><td></td>","<td class='diff-row diff-row-last'></td><td><ins>#{event.new_element}</ins></td>"]
    end
    
    def change(event)
      old = event.old_element.split(/\s/)
      new = event.new_element.split(/\s/)
      d = WordDiff.new
      Diff::LCS.traverse_sequences(old,new,d)
      old, new = d.transpose
      @rows << ["<td class='diff-row diff-row-first'></td><td><del>#{old.join("")}</del></td>", "<td class='diff-row diff-row-last'></td><td><ins>#{new.join("")}</ins></td>"]
    end
  end 

  def self.diff(a,b)
    d = ParagraphDiff.new
    Diff::LCS.traverse_balanced(a,b,d)
    return d.to_html
  end
end
