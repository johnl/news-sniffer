module HTMLDiff
  require 'diff/lcs'
  require 'diff/lcs/callbacks'
  
  class HtmlDiff

    def to_html
      @rows.collect { |row| "<tr><td>#{row.first}</td><td>#{row.last}</td></tr>" }.join("\n")
    end

    def initialize
      @rows = []
    end

    def match(event)
      @rows << [event.old_element, event.new_element]
    end

    def discard_a(event)
      @rows << ["<del>#{event.old_element}</del>", ""]
    end

    def discard_b(event)
      @rows << ["","<ins>#{event.new_element}</ins>"]
    end
    
    def change(event)
      @rows << ["<del>#{event.old_element}</del>", "<ins>#{event.new_element}</ins>"]
    end
  end 

  def self.diff(a,b)
    d = HtmlDiff.new
    Diff::LCS.traverse_balanced(a,b,d)
    return d.to_html
  end
end
